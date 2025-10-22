const ws = new WebSocket("ws://localhost:3000");
ws.onopen = () => {
  ws.send(JSON.stringify({ type: "register", username: "ala", password: "kot" }));
  ws.send(JSON.stringify({ type: "login", username: "ala", password: "kot" }));
  ws.send(JSON.stringify({ type: "getLast10" }));
};
ws.onmessage = (e) => console.log("Serwer:", JSON.parse(e.data));
