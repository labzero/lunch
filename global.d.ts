import { Action } from "redux";
import WebSocket from "ws";
import { Team, User as UserInterface } from "./src/interfaces";

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
      wss?: Server;
    }
    export interface User extends UserInterface {}
  }
}

interface ExtWebSocket extends WebSocket {
  teamId?: number;
}

type Dispose = () => void;
type InsertCssItem = () => Dispose;
type GetCSSItem = () => string;
type GetContent = () => string;

interface Style {
  [key: string]: InsertCssItem | GetCSSItem | GetContent | string;
  _insertCss: InsertCssItem;
  _getCss: GetCSSItem;
  _getContent: GetContent;
}

declare module "*.scss" {
  const style: Style;
  export default style;
}

declare module "*.css" {
  const style: Style;
  export default style;
}

declare module "isomorphic-style-loader/useStyles" {
  function useStyles(...styles: Style[]): void;
  export default useStyles;
}

declare module "isomorphic-style-loader/StyleContext" {
  import { Context } from "react";

  type RemoveGlobalCss = () => void;
  type InsertCSS = (...styles: Style[]) => RemoveGlobalCss | void;
  interface StyleContextValue {
    insertCss: InsertCSS;
  }

  const StyleContext: Context<StyleContextValue>;

  export { StyleContext as default, InsertCSS };
}

declare module "express-serve-static-core" {
  interface Express {
    hot: __WebpackModuleApi.Hot;
  }
}
