declare var  __webpack_public_path__: string;
declare var __DEV__: boolean;

type Dispose = () => void
type InsertCssItem = () => Dispose
type GetCSSItem = () => string
type GetContent = () => string

interface Style {
  [key: string]: InsertCssItem | GetCSSItem | GetContent | string
  _insertCss: InsertCssItem
  _getCss: GetCSSItem
  _getContent: GetContent
}

declare module "*.scss" {
  const style: Style
  export default style
}

declare module 'react-deep-force-update';
