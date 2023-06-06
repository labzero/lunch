class RobustWebSocket extends WebSocket {
  attempts: number;

  constructor(
    url: Parameters<WebSocket["new"]>[0],
    protocols: Parameters<WebSocket["new"]>[1],
    options?: Record<string, any>
  ): RobustWebsocket;
}

declare module "robust-websocket" {
  export default RobustWebSocket;
}
