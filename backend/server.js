require('dotenv').config();
const express = require('express');
const cors = require('cors');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const pool = require('./db');
const { publicarReset, esp32EnLinea } = require('./mqtt');
const { verificarToken, verificarRol } = require('./auth');

const app = express();
app.use(cors());
app.use(express.json());

// Ruta de comprobación: confirma que el backend está vivo
// y que puede hablar con MySQL, sin exponer datos sensibles.
app.get('/api/health', async (req, res) => {
    try {
        await pool.query('SELECT 1');
        res.json({ status: 'ok', database: 'connected' });
    } catch (error) {
        res.status(500).json({ status: 'error', message: error.message });
    }
});

// Login: recibe usuario y contraseña, verifica contra MySQL,
// y devuelve un token JWT si las credenciales son correctas.
app.post('/api/login', async (req, res) => {
    const { nombre_usuario, password } = req.body;

    if (!nombre_usuario || !password) {
        return res.status(400).json({ error: 'Usuario y contraseña son requeridos' });
    }

    try {
        const [filas] = await pool.query(
            `SELECT u.id_usuario, u.nombre_usuario, u.password_hash, u.activo, r.nombre_rol
             FROM usuarios u
             JOIN roles r ON u.id_rol = r.id_rol
             WHERE u.nombre_usuario = ?`,
            [nombre_usuario]
        );

        if (filas.length === 0) {
            return res.status(401).json({ error: 'Credenciales inválidas' });
        }

        const usuario = filas[0];

        if (!usuario.activo) {
            return res.status(403).json({ error: 'Usuario inactivo' });
        }

        const passwordValida = await bcrypt.compare(password, usuario.password_hash);

        if (!passwordValida) {
            return res.status(401).json({ error: 'Credenciales inválidas' });
        }

        const token = jwt.sign(
            {
                id_usuario: usuario.id_usuario,
                nombre_usuario: usuario.nombre_usuario,
                rol: usuario.nombre_rol
            },
            process.env.JWT_SECRET,
            { expiresIn: '8h' }
        );

        res.json({
            token,
            usuario: {
                nombre_usuario: usuario.nombre_usuario,
                rol: usuario.nombre_rol
            }
        });

    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

// ⬇️⬇️⬇️ RUTAS DEL PASO 5 ⬇️⬇️⬇️

app.get('/api/variadores', verificarToken, async (req, res) => {
    try {
        const [variadores] = await pool.query(
            `SELECT v.id_variador, v.descripcion, v.activo,
                    (SELECT e.id_evento
                     FROM eventos e
                     WHERE e.id_variador = v.id_variador
                       AND e.fin_alarma IS NULL
                     ORDER BY e.inicio_alarma ASC
                     LIMIT 1) AS evento_activo,
                    (SELECT e.inicio_alarma
                     FROM eventos e
                     WHERE e.id_variador = v.id_variador
                       AND e.fin_alarma IS NULL
                     ORDER BY e.inicio_alarma ASC
                     LIMIT 1) AS inicio_alarma
             FROM variadores v
             ORDER BY v.id_variador`
        );

        const enLinea = esp32EnLinea();

        const resultado = variadores.map((v) => ({
            id_variador: v.id_variador,
            descripcion: v.descripcion,
            activo: !!v.activo,
            // Sin comunicación tiene prioridad sobre cualquier otro
            // estado, porque con el ESP32 caído la alarma guardada en
            // MySQL puede estar desactualizada.
            estado: !enLinea
                ? 'SIN_COMUNICACION'
                : (v.evento_activo ? 'ALARMA' : 'NORMAL'),
            en_alarma_desde: v.inicio_alarma
        }));

        res.json(resultado);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

app.post('/api/variadores/:id/reset', verificarToken, verificarRol('ADMINISTRADOR', 'ELECTRICISTA'), async (req, res) => {
    const idVariador = parseInt(req.params.id, 10);

    if (idVariador < 1 || idVariador > 8) {
        return res.status(400).json({ error: 'Variador inválido' });
    }

    try {
        const [variadores] = await pool.query(
            'SELECT activo FROM variadores WHERE id_variador = ?',
            [idVariador]
        );

        if (variadores.length === 0 || !variadores[0].activo) {
            return res.status(400).json({ error: 'Ese variador no está activo en el sistema' });
        }

        // Un reset enviado mientras el ESP32 está desconectado se perdería
        // sin aviso: el comando no se guarda en el broker.
        if (!esp32EnLinea()) {
            return res.status(503).json({
                error: 'Sin comunicación con el ESP32. El comando no se puede entregar.'
            });
        }

        publicarReset(idVariador);
        res.json({ mensaje: `Comando de reset enviado al variador ${idVariador}` });

    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

// ⬇️⬇️⬇️ RUTA DEL PASO 12: BITÁCORA ⬇️⬇️⬇️

app.get('/api/variadores/:id/eventos', verificarToken, async (req, res) => {
    const idVariador = parseInt(req.params.id, 10);

    try {
        const [eventos] = await pool.query(
            `SELECT id_evento, inicio_alarma, fin_alarma, duracion_segundos
             FROM eventos
             WHERE id_variador = ?
             ORDER BY inicio_alarma DESC
             LIMIT 100`,
            [idVariador]
        );

        res.json(eventos);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

// ⬇️⬇️⬇️ RUTAS DEL PASO 13: ADMINISTRACIÓN ⬇️⬇️⬇️

app.get('/api/usuarios', verificarToken, verificarRol('ADMINISTRADOR'), async (req, res) => {
    try {
        const [usuarios] = await pool.query(
            `SELECT u.id_usuario, u.nombre_usuario, u.activo, r.nombre_rol
             FROM usuarios u
             JOIN roles r ON u.id_rol = r.id_rol
             ORDER BY u.id_usuario`
        );
        res.json(usuarios);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

app.post('/api/usuarios', verificarToken, verificarRol('ADMINISTRADOR'), async (req, res) => {
    const { nombre_usuario, password, rol } = req.body;

    if (!nombre_usuario || !password || !rol) {
        return res.status(400).json({ error: 'Faltan datos requeridos' });
    }

    try {
        const [roles] = await pool.query('SELECT id_rol FROM roles WHERE nombre_rol = ?', [rol]);
        if (roles.length === 0) {
            return res.status(400).json({ error: 'Rol inválido' });
        }

        const hash = await bcrypt.hash(password, 10);
        await pool.query(
            'INSERT INTO usuarios (nombre_usuario, password_hash, id_rol) VALUES (?, ?, ?)',
            [nombre_usuario, hash, roles[0].id_rol]
        );

        res.json({ mensaje: 'Usuario creado correctamente' });
    } catch (error) {
        if (error.code === 'ER_DUP_ENTRY') {
            return res.status(409).json({ error: 'Ese nombre de usuario ya existe' });
        }
        console.error(error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

app.patch('/api/usuarios/:id/estado', verificarToken, verificarRol('ADMINISTRADOR'), async (req, res) => {
    const { activo } = req.body;
    try {
        await pool.query('UPDATE usuarios SET activo = ? WHERE id_usuario = ?', [activo, req.params.id]);
        res.json({ mensaje: 'Usuario actualizado' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

app.patch('/api/usuarios/:id', verificarToken, verificarRol('ADMINISTRADOR'), async (req, res) => {
    const { nombre_usuario, password } = req.body;
    const idUsuario = parseInt(req.params.id, 10);

    try {
        const campos = [];
        const valores = [];

        if (nombre_usuario !== undefined) {
            const nombreLimpio = nombre_usuario.trim();
            if (nombreLimpio === '') {
                return res.status(400).json({ error: 'El nombre de usuario no puede estar vacío' });
            }
            campos.push('nombre_usuario = ?');
            valores.push(nombreLimpio);
        }

        if (password !== undefined && password !== '') {
            const hash = await bcrypt.hash(password, 10);
            campos.push('password_hash = ?');
            valores.push(hash);
        }

        if (campos.length === 0) {
            return res.status(400).json({ error: 'Nada que actualizar' });
        }

        valores.push(idUsuario);
        await pool.query(`UPDATE usuarios SET ${campos.join(', ')} WHERE id_usuario = ?`, valores);

        res.json({ mensaje: 'Usuario actualizado correctamente' });
    } catch (error) {
        if (error.code === 'ER_DUP_ENTRY') {
            return res.status(409).json({ error: 'Ese nombre de usuario ya existe' });
        }
        console.error(error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

app.patch('/api/variadores/:id', verificarToken, verificarRol('ADMINISTRADOR'), async (req, res) => {
    const { descripcion, activo } = req.body;
    const idVariador = parseInt(req.params.id, 10);

    if (idVariador < 1 || idVariador > 8) {
        return res.status(400).json({ error: 'Variador inválido' });
    }

    try {
        const campos = [];
        const valores = [];

        if (descripcion !== undefined) {
            campos.push('descripcion = ?');
            valores.push(descripcion);
        }
        if (activo !== undefined) {
            campos.push('activo = ?');
            valores.push(activo);
        }

        if (campos.length === 0) {
            return res.status(400).json({ error: 'Nada que actualizar' });
        }

        valores.push(idVariador);
        await pool.query(`UPDATE variadores SET ${campos.join(', ')} WHERE id_variador = ?`, valores);

        res.json({ mensaje: 'Variador actualizado' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error interno del servidor' });
    }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () =>
  console.log(`Backend escuchando en el puerto ${PORT} en todas las interfaces`)
);