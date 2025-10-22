const express = require("express");
const http = require("http");
const WebSocket = require("ws");
const mqtt = require("mqtt");

const PORT = process.env.PORT || 3000;
const MQTT_URL = process.env.MQTT_URL || "mqtt://localhost:1883"; //do zmiany na brokera w VM, jeśli będzie miał inny adres ip
const MQTT_TOPIC = process.env.MQTT_TOPIC || "incoming/data";

const users = [];     // [{ username, password }]
const dataStore = []; // [{ by, topic, payload, ts }]

const app = express();
const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

//additional healthcheck
app.get("/health", (_req, res) => res.status(200).send("OK"));

//websocket heartbeat for client to ping every 30s keepalive
function heartbeat() { this.isAlive = true; }
setInterval(() => {
  wss.clients.forEach((ws) => {
    if (ws.isAlive === false) return ws.terminate();
    ws.isAlive = false;
    try { ws.ping(); } catch {}
  });
}, 30000);

//websocket connection register/login/get10
wss.on("connection", (ws) => {

  ws.isAlive = true;
  ws.on("pong", heartbeat);

  ws.auth = { loggedIn: false, username: null };

  const send = (type, data) => {
    try { ws.send(JSON.stringify({ type, ...data })); } catch {}
  };

  send("hello", {
    message: "connected"
  });

  ws.on("message", (raw) => {
    let msg;
    try { msg = JSON.parse(raw.toString()); }
    catch { return send("error", { error: "wrong JSON" }); }

    const { type } = msg || {};
    if (!type) return send("error", { error: "missing type" });

    switch (type) {
      case "register": {
        const { username, password } = msg;

        if (!username || !password)
          return send("error", { error: "Required username/password" });
        if (users.find(u => u.username === username))
          return send("error", { error: "User exists" });

        users.push({ username, password });
        return send("registerSuccess", { username });
      }

      case "login": {
        const { username, password } = msg;

        if (!username || !password)
          return send("error", { error: "Required username/password" });
        const u = users.find(u => u.username === username);
        if (!u || u.password !== password)
          return send("error", { error: "Wrong login data" });

        ws.auth = { loggedIn: true, username };
        return send("loginSuccess", { username });
      }

      case "getLast10": {
        if (!ws.auth.loggedIn)
          return send("error", { error: "Login required" });

        const last10 = dataStore.slice(-10);
        return send("last10", { count: last10.length, items: last10 });
      }

      default:
        return send("error", { error: "unknown type" });
    }
  });
});

//mqtt
const mqttClient = mqtt.connect(MQTT_URL, {
  reconnectPeriod: 5000, // auto-reconnect
});

mqttClient.on("connect", () => {
  console.log(`Connected with broker: ${MQTT_URL}`);

  mqttClient.subscribe(MQTT_TOPIC, (err) => {
    if (err) {
      console.error("Sub error", err.message);
    } else {
      console.log(`Subscribing to: ${MQTT_TOPIC}`);
    }
  });
});

mqttClient.on("message", (topic, message) => {
  let payload = null;
  try { payload = JSON.parse(message.toString()); }
  catch { payload = { raw: message.toString() }; }

  const entry = {
    by: "mqtt",      
    topic,
    payload,
    ts: new Date().toISOString(),
  };
  dataStore.push(entry);

  //data limit
  if (dataStore.length > 10000) dataStore.shift();
});

mqttClient.on("error", (err) => {
  console.error("MQTT error:", err.message);
});

// ---- Start ----
server.listen(PORT, () => {
  console.log(`WS server: ws://localhost:${PORT}`);
  console.log(`MQTT broker: ${MQTT_URL} | topic: ${MQTT_TOPIC}`);
});
