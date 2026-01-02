const net = require('net');
const http = require('http');
const WebSocket = require('ws');

const GAME_SERVER_HOST = '127.0.0.1';
const GAME_SERVER_PORT = 17091;
const WS_PORT = process.env.PORT || 8080;

// Create WebSocket server
const server = http.createServer();
const wss = new WebSocket.Server({ server });

console.log(`WebSocket proxy starting on port ${WS_PORT}...`);

wss.on('connection', (ws) => {
  console.log('Client connected via WebSocket');

  // Connect to game server
  const gameSocket = net.connect(GAME_SERVER_PORT, GAME_SERVER_HOST, () => {
    console.log('Connected to game server');
  });

  // Forward data:  WebSocket → Game Server
  ws.on('message', (data) => {
    gameSocket. write(data);
  });

  // Forward data: Game Server → WebSocket
  gameSocket.on('data', (data) => {
    if (ws.readyState === WebSocket. OPEN) {
      ws.send(data);
    }
  });

  // Handle disconnections
  ws.on('close', () => {
    console.log('WebSocket client disconnected');
    gameSocket.end();
  });

  gameSocket.on('close', () => {
    console.log('Game server connection closed');
    ws.close();
  });

  gameSocket.on('error', (err) => {
    console.error('Game server error:', err);
    ws.close();
  });

  ws.on('error', (err) => {
    console.error('WebSocket error:', err);
    gameSocket.end();
  });
});

server.listen(WS_PORT, '0.0.0.0', () => {
  console.log(`✓ WebSocket proxy listening on port ${WS_PORT}`);
});
