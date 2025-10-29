const express = require("express");
const http = require("http");
const WebSocket = require("ws");
const mqtt = require("mqtt");
require('dotenv').config();

const PORT = process.env.PORT || 3000;
const MQTT_URL = process.env.MQTT_URL || "mqtt://localhost:1883"; //do zmiany na brokera w VM, jeśli będzie miał inny adres ip

const users = [];     // [{ firstName, lastName, email, password }]

// [{ payload, ts }]
const dataPh = []
const dataTemp = []
const dataWeight = []
const dataOutside = []

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
        console.log("register", users)
        const { firstName, lastName, email, password } = msg;

        if (!firstName || !lastName || !email || !password)
          return send("error", { error: "Required username/password" });
        if (users.find(u => (u.firstName === firstName && u.lastName === lastName && u.email === email)))
          return send("error", { error: "User exists" });

        users.push({ firstName, lastName, email, password });
        ws.auth = { loggedIn: true, ...{ firstName, lastName, email, password }};
        return send("registerSuccess", { firstName, lastName, email });
      }

      case "login": {
        console.log("login", users)
        const { email, password } = msg;

        if (!email || !password)
          return send("error", { error: "Required username/password" });
        const u = users.find(u => u.email === email);
        if (!u || u.password !== password)
          return send("error", { error: "Wrong login data" });

        ws.auth = { loggedIn: true, ...u };
        return send("loginSuccess", {...u});
      }

      case "getTemp": {
        if (!ws.auth.loggedIn)
          return send("error", { error: "Login required" });

        const last10 = dataTemp.slice(-10);
        return send("last10", { count: last10.length, items: last10 });
      }

      case "getPh": {
        if (!ws.auth.loggedIn)
          return send("error", { error: "Login required" });

        const last10 = dataPh.slice(-10);
        return send("last10", { count: last10.length, items: last10 });
      }

      case "getWeight": {
        if (!ws.auth.loggedIn)
          return send("error", { error: "Login required" });

        const last10 = dataWeight.slice(-10);
        return send("last10", { count: last10.length, items: last10 });
      }

      case "getOutside": {
        if (!ws.auth.loggedIn)
          return send("error", { error: "Login required" });

        const last10 = dataOutside.slice(-10);
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

  mqttClient.subscribe(["ph", "weight", "temp", "outside"], (err) => {
    if (err) console.error("Sub error", err.message);
    else console.log("Subscribing to: ph, weight, temp, outside");
  });

});

mqttClient.on("message", (topic, message) => {
  let payload = null;
  try { payload = JSON.parse(message.toString()); }
  catch { payload = { raw: message.toString() }; }

  const entry = {
    payload,
    ts: new Date().toISOString(),
  };

  console.log(entry)

  switch(topic) {
    case "ph":
      dataPh.push(entry);
      if (dataPh.length > 10000) dataPh.shift();
      break;

    case "weight":
      dataWeight.push(entry);
      if (dataWeight.length > 10000) dataWeight.shift();
      break;

    case "temp":
      dataTemp.push(entry);
      if (dataTemp.length > 10000) dataTemp.shift();
      break;

    case "outside":
      dataOutside.push(entry);
      if (dataOutside.length > 10000) dataOutside.shift();
      break;

    default:
      console.warn("unkown topic: ", topic);
  }

  console.log("ph: ",dataPh,"weight: ",dataWeight,"temp: ", dataTemp, "outside:", dataOutside)
});

mqttClient.on("error", (err) => {
  console.error("MQTT error:", err.message);
});

// ---- Start ----
server.listen(PORT, () => {
  console.log(`WS server: ws://localhost:${PORT}`);
  console.log(`MQTT broker: ${MQTT_URL} `);
});
