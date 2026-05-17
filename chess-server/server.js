const WebSocket = require('ws');

const wss = new WebSocket.Server({ port: 3000 });

let waiting = null;
let games = new Map();

wss.on('connection', (ws) => {
    console.log("Player connected");

    if (waiting) {
        const gameId = Math.random().toString(36).substring(7);

        games.set(gameId, [waiting, ws]);

        waiting.gameId = gameId;
        ws.gameId = gameId;

        waiting.send(JSON.stringify({ type: "start", color: "white" }));
        ws.send(JSON.stringify({ type: "start", color: "black" }));

        waiting = null;
    } else {
        waiting = ws;
    }

    ws.on('message', (message) => {
        const data = JSON.parse(message);

        if (data.type === "move") {
            const players = games.get(ws.gameId);
            if (!players) return;

            players.forEach(p => {
                if (p !== ws) {
                    p.send(JSON.stringify({
                        type: "move",
                        move: data.move
                    }));
                }
            });
        }
    });

    ws.on('close', () => {
        console.log("Disconnected");
        waiting = null;
    });
});

console.log("WebSocket server running on port 3000");
