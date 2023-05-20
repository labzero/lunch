import { Action } from "redux";
import WebSocket from "ws";
import { Team, User as UserInterface } from "../src/interfaces";

declare global {
  interface Window {
    App: any;
  }
  namespace Express {
    export interface Request {
      broadcast: (teamId: number, data: Action) => void;
      subdomain?: string;
      team?: Team;
      user?: UserInterface;
      wss?: WebSocket.Server;
    }
    export interface User extends UserInterface {}
  }
}
