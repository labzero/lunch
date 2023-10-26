declare const __webpack_public_path__: string;
declare const __DEV__: boolean;

/// <reference types="webpack-env" />
/// <reference types="chai-jsdom" />

declare interface Window {
  swUpdate?: boolean;
}

namespace global {
  let Bun: { [index: string]: any } | undefined;
}

type Dispose = () => void;
type InsertCssItem = () => Dispose;
type GetCSSItem = () => string;
type GetContent = () => string;

interface Style {
  [key: string]: string;
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

declare module "*.png" {
  const value: string;
  export default value;
}

declare module "*.svg" {
  const value: string;
  export default value;
}
