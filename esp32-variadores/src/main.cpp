#include <WiFi.h>
#include <PubSubClient.h>
#include "secrets.h"

WiFiClient espClient;
PubSubClient mqttClient(espClient);

const char* CLIENT_ID = "esp32_variadores_001";
const char* TOPIC_STATUS = "industrial/esp32/status";

// ============================================================
// CONFIGURACIÓN DE LOS 8 VARIADORES
// ============================================================
// Cada variador tiene un GPIO de entrada (alarma) y uno de salida (reset).
// Los índices van de 0 a 7, que corresponden a los variadores 1 a 8.

const int NUM_VARIADORES = 8;

const int PIN_ALARMA[8] = { 4,  5, 13, 14, 16, 17, 18, 19};
const int PIN_RESET[8]  = {21, 22, 23, 25, 26, 27, 32, 33};

// Duración del pulso de reset (ms)
const unsigned long DURACION_PULSO_RESET = 500;

// ============================================================
// TEMPORIZACIÓN
// ============================================================
unsigned long ultimoIntentoMQTT = 0;
unsigned long ultimoHeartbeat = 0;
unsigned long ultimaLecturaGPIO = 0;
const unsigned long INTERVALO_RECONEXION = 5000;
const unsigned long INTERVALO_HEARTBEAT = 30000;     // 30 s (menos spam)
const unsigned long INTERVALO_LECTURA_GPIO = 200;    // 200 ms

// ============================================================
// ESTADO ACTUAL DE CADA VARIADOR
// ============================================================
// Guardamos el último estado publicado para no repetir mensajes innecesarios.
// Estado inicial: "DESCONOCIDO" (hasta la primera lectura).
String estadoActual[8] = {
    "DESCONOCIDO", "DESCONOCIDO", "DESCONOCIDO", "DESCONOCIDO",
    "DESCONOCIDO", "DESCONOCIDO", "DESCONOCIDO", "DESCONOCIDO"
};

// ============================================================
// FUNCIONES DE RED
// ============================================================
void conectarWiFi() {
    Serial.print("Conectando a WiFi: ");
    Serial.println(WIFI_SSID);

    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        Serial.print(".");
    }

    WiFi.setSleep(false);

    Serial.println();
    Serial.print("WiFi conectado. IP: ");
    Serial.println(WiFi.localIP());
}

// ============================================================
// CALLBACK: mensajes MQTT entrantes
// ============================================================
void alRecibirMensaje(char* topic, byte* payload, unsigned int longitud) {
    // Construir el topic como string
    String strTopic = String(topic);
    String mensaje = "";
    for (unsigned int i = 0; i < longitud; i++) {
        mensaje += (char)payload[i];
    }

    Serial.println();
    Serial.println(">>> MENSAJE MQTT RECIBIDO <<<");
    Serial.print("Topic: ");
    Serial.println(strTopic);
    Serial.print("Payload: ");
    Serial.println(mensaje);

    // Verificar si es un topic de reset: industrial/variadores/N/reset
    // N va del 1 al 8.
    for (int i = 0; i < NUM_VARIADORES; i++) {
        String topicResetEsperado = "industrial/variadores/" + String(i + 1) + "/reset";

        if (strTopic == topicResetEsperado) {
            Serial.print(">>> ACTIVANDO RESET DEL VARIADOR ");
            Serial.print(i + 1);
            Serial.println(" <<<");

            // Pulso de reset
            digitalWrite(PIN_RESET[i], HIGH);
            delay(DURACION_PULSO_RESET);
            digitalWrite(PIN_RESET[i], LOW);

            Serial.println(">>> RESET COMPLETADO <<<");
            return;
        }
    }

    Serial.println("Topic no reconocido, ignorado.");
}

// ============================================================
// CONEXIÓN AL BROKER
// ============================================================
bool intentarConectarMQTT() {
    if (mqttClient.connected()) return true;

    Serial.print("Conectando a MQTT...");

    bool conectado = mqttClient.connect(
        CLIENT_ID, MQTT_USER, MQTT_PASSWORD,
        TOPIC_STATUS, 1, true, "offline"
    );

    if (conectado) {
        Serial.println(" conectado");
        mqttClient.publish(TOPIC_STATUS, "online", true);

        // Suscribirse a los 8 topics de reset, uno por cada variador.
        // Alternativamente, podríamos suscribirnos a "industrial/variadores/+/reset"
        // pero preferimos hacerlo explícito para tener control exacto.
        for (int i = 0; i < NUM_VARIADORES; i++) {
            String topic = "industrial/variadores/" + String(i + 1) + "/reset";
            bool suscrito = mqttClient.subscribe(topic.c_str(), 1);
            Serial.print("Suscrito a ");
            Serial.print(topic);
            Serial.print(": ");
            Serial.println(suscrito ? "true" : "false");
        }

        return true;
    } else {
        Serial.print(" falló, código: ");
        Serial.print(mqttClient.state());
        Serial.println(" -- se reintentará");
        return false;
    }
}

// ============================================================
// LECTURA DE GPIOs Y PUBLICACIÓN DE CAMBIOS
// ============================================================
void leerYPublicarEstados() {
    for (int i = 0; i < NUM_VARIADORES; i++) {
        int valorGPIO = digitalRead(PIN_ALARMA[i]);
        String nuevoEstado = (valorGPIO == HIGH) ? "ALARMA" : "NORMAL";

        if (nuevoEstado != estadoActual[i]) {
            estadoActual[i] = nuevoEstado;

            Serial.print(">>> Cambio detectado: Variador ");
            Serial.print(i + 1);
            Serial.print(" = ");
            Serial.println(nuevoEstado);

            String topicEstado = "industrial/variadores/" + String(i + 1) + "/estado";
            mqttClient.publish(topicEstado.c_str(), nuevoEstado.c_str());
        }
    }
}

// ============================================================
// SETUP
// ============================================================
void setup() {
    Serial.begin(115200);
    delay(1000);

    Serial.println();
    Serial.println("=== IIOT VARIADORES - ESP32 ===");
    Serial.println();

    // Configurar pines
    for (int i = 0; i < NUM_VARIADORES; i++) {
        pinMode(PIN_ALARMA[i], INPUT);
        pinMode(PIN_RESET[i], OUTPUT);
        digitalWrite(PIN_RESET[i], LOW);
    }
    Serial.println("GPIOs configurados.");

    conectarWiFi();

    mqttClient.setServer(MQTT_HOST, MQTT_PORT);
    mqttClient.setCallback(alRecibirMensaje);
    mqttClient.setBufferSize(512);

    while (!intentarConectarMQTT()) {
        delay(2000);
    }

    Serial.println();
    Serial.println("Sistema listo. Leyendo estados cada 200 ms...");
    Serial.println();
}

// ============================================================
// LOOP
// ============================================================
void loop() {
    // 1. Verificar WiFi
    if (WiFi.status() != WL_CONNECTED) {
        Serial.println("WiFi desconectado, reintentando...");
        conectarWiFi();
    }

    // 2. Verificar MQTT
    if (!mqttClient.connected()) {
        unsigned long ahora = millis();
        if (ahora - ultimoIntentoMQTT >= INTERVALO_RECONEXION) {
            ultimoIntentoMQTT = ahora;
            intentarConectarMQTT();
        }
    }

    // 3. Procesar mensajes MQTT entrantes
    mqttClient.loop();

    // 4. Leer GPIOs y publicar cambios
    unsigned long ahora = millis();
    if (ahora - ultimaLecturaGPIO >= INTERVALO_LECTURA_GPIO) {
        ultimaLecturaGPIO = ahora;
        leerYPublicarEstados();
    }

    // 5. Heartbeat reducido (cada 30 s)
    if (ahora - ultimoHeartbeat >= INTERVALO_HEARTBEAT) {
        ultimoHeartbeat = ahora;
        Serial.print("[heartbeat] uptime: ");
        Serial.print(ahora / 1000);
        Serial.print(" s | mqtt.connected(): ");
        Serial.print(mqttClient.connected() ? "true" : "false");
        Serial.print(" | mqtt.state(): ");
        Serial.println(mqttClient.state());
    }
}