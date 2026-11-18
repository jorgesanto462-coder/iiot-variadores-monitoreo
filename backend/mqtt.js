const mqtt = require('mqtt');
require('dotenv').config();
const pool = require('./db');

const client = mqtt.connect(process.env.MQTT_HOST, {
    username: process.env.MQTT_USER,
    password: process.env.MQTT_PASSWORD,
    reconnectPeriod: 2000
});

// null = todavía no se ha recibido ningún mensaje de estado desde que
// arrancó el backend. Se distingue de false para no mandar un aviso de
// Telegram por el simple hecho de arrancar.
let esp32Online = null;

// El ESP32 se considera en línea solo si el broker dice "online" Y el
// propio backend está conectado al broker. Si el backend pierde su
// conexión MQTT, tampoco puede garantizar que los datos sean actuales.
function esp32EnLinea() {
    return client.connected && esp32Online === true;
}

client.on('connect', () => {
    console.log('Backend conectado al broker MQTT');

    client.subscribe('industrial/variadores/+/estado', (error) => {
        if (error) {
            console.error('Error al suscribirse a estados:', error.message);
        } else {
            console.log('Suscrito a industrial/variadores/+/estado');
        }
    });

    client.subscribe('industrial/esp32/status', (error) => {
        if (!error) console.log('Suscrito a industrial/esp32/status');
    });
});

client.on('error', (error) => {
    console.error('Error de conexión MQTT:', error.message);
});

// Cada vez que llega un mensaje a cualquier topic suscrito, esta
// función se ejecuta. Extraemos el número de variador del topic
// mismo, en lugar de pedirlo dentro del contenido del mensaje.
client.on('message', async (topic, mensaje) => {
    const contenido = mensaje.toString();
    console.log(`Mensaje recibido en ${topic}: ${contenido}`);

    // Topic de estado del ESP32 (online/offline)
    if (topic === 'industrial/esp32/status') {
        const estabaEnLinea = esp32Online;
        esp32Online = (contenido === 'online');

        // Solo se avisa cuando hay un cambio real respecto a un estado
        // anterior conocido.
        if (estabaEnLinea !== null && estabaEnLinea !== esp32Online) {
            await enviarTelegram(
                esp32Online
                    ? '✅ <b>Comunicación con el ESP32 restablecida</b>\n\nLos estados de los variadores son confiables de nuevo.'
                    : '⚠️ <b>Se perdió la comunicación con el ESP32</b>\n\nLos estados de los variadores NO son confiables hasta que el ESP32 regrese.'
            );
        }
        return;
    }

    const coincide = topic.match(/^industrial\/variadores\/(\d+)\/estado$/);

    if (coincide) {
        const idVariador = parseInt(coincide[1], 10);
        await procesarCambioEstado(idVariador, contenido);
    }
});

// ⬇️⬇️⬇️ FUNCIONES AUXILIARES DE TELEGRAM ⬇️⬇️⬇️

async function enviarTelegram(texto) {
    const token = process.env.TELEGRAM_TOKEN;
    const chatId = process.env.TELEGRAM_CHAT_ID;

    if (!token || !chatId) {
        console.warn('Telegram no está configurado en el .env');
        return;
    }

    try {
        const respuesta = await fetch(
            `https://api.telegram.org/bot${token}/sendMessage`,
            {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    chat_id: chatId,
                    text: texto,
                    parse_mode: 'HTML',
                    disable_web_page_preview: false
                })
            }
        );

        if (!respuesta.ok) {
            console.error(`Telegram respondió con estado ${respuesta.status}`);
        }
    } catch (error) {
        console.error('No se pudo enviar el mensaje a Telegram:', error.message);
    }
}

function formatearDuracion(segundos) {
    const minutos = Math.floor(segundos / 60);
    const resto = segundos % 60;
    return minutos > 0 ? `${minutos} min ${resto} seg` : `${resto} seg`;
}

function horaActual() {
    const fecha = new Date();
    const dia = fecha.getDate().toString().padStart(2, '0');
    const mes = (fecha.getMonth() + 1).toString().padStart(2, '0');
    const anio = fecha.getFullYear();
    const hora = fecha.getHours().toString().padStart(2, '0');
    const minuto = fecha.getMinutes().toString().padStart(2, '0');
    const segundo = fecha.getSeconds().toString().padStart(2, '0');
    return `${dia}/${mes}/${anio} ${hora}:${minuto}:${segundo}`;
}

// ⬇️⬇️⬇️ PROCESAMIENTO DE CAMBIOS DE ESTADO ⬇️⬇️⬇️

async function procesarCambioEstado(idVariador, estado) {
    if (estado !== 'ALARMA' && estado !== 'NORMAL') return;

    try {
        const [info] = await pool.query(
            'SELECT descripcion, activo FROM variadores WHERE id_variador = ?',
            [idVariador]
        );

        if (info.length === 0 || !info[0].activo) return;

        const descripcion = info[0].descripcion;
        const nombre = descripcion === `Variador ${idVariador}`
            ? `Variador ${idVariador}`
            : `Variador ${idVariador} (${descripcion})`;

        const [abiertos] = await pool.query(
            `SELECT id_evento FROM eventos
             WHERE id_variador = ? AND fin_alarma IS NULL
             ORDER BY inicio_alarma DESC LIMIT 1`,
            [idVariador]
        );

        const sistemaUrl = process.env.SISTEMA_URL || 'http://localhost:5000';

        if (estado === 'ALARMA') {
            if (abiertos.length > 0) return;

            await pool.query(
                'INSERT INTO eventos (id_variador, inicio_alarma) VALUES (?, NOW())',
                [idVariador]
            );
            console.log(`Variador ${idVariador}: nueva alarma registrada`);

            const mensaje = `
🚨 <b>ALARMA - ${nombre}</b>

El <b>${nombre}</b> entró en estado de ALARMA.
🕒 Hora: ${horaActual()}

<a href="${sistemaUrl}">👉 Abrir Dashboard</a>
`.trim();

            await enviarTelegram(mensaje);

        } else {
            if (abiertos.length === 0) return;

            const idEvento = abiertos[0].id_evento;
            await pool.query(
                `UPDATE eventos
                 SET fin_alarma = NOW(),
                     duracion_segundos = TIMESTAMPDIFF(SECOND, inicio_alarma, NOW())
                 WHERE id_evento = ?`,
                [idEvento]
            );

            const [cerrado] = await pool.query(
                'SELECT duracion_segundos FROM eventos WHERE id_evento = ?',
                [idEvento]
            );

            const duracion = formatearDuracion(cerrado[0].duracion_segundos);
            console.log(`Variador ${idVariador}: alarma restablecida`);

            const mensaje = `
✅ <b>RESTABLECIDO - ${nombre}</b>

El <b>${nombre}</b> volvió a estado NORMAL.
🕒 Hora: ${horaActual()}
⏱️ Duración de la alarma: ${duracion}

<a href="${sistemaUrl}">👉 Abrir Dashboard</a>
`.trim();

            await enviarTelegram(mensaje);
        }
    } catch (error) {
        console.error('Error al procesar cambio de estado:', error.message);
    }
}

function publicarReset(idVariador) {
    const topic = `industrial/variadores/${idVariador}/reset`;
    client.publish(topic, 'RESET', { qos: 1 }, (error) => {
        if (error) {
            console.error(`Error al publicar reset para variador ${idVariador}:`, error.message);
        } else {
            console.log(`Reset publicado para variador ${idVariador}`);
        }
    });
}

module.exports = { client, publicarReset, esp32EnLinea };