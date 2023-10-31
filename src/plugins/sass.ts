import { plugin } from "bun";
import { postcssModules, sassPlugin } from "esbuild-sass-plugin";
import postcssUrl from "postcss-url";
import assetFromPath from "./helpers/assetFromPath";

const pluginOpts = {
  cssImports: true,
};

const setupOpts = (build) => ({
  initialOptions: {},
  onResolve: build.onResolve,
  onStart: () => {},
  resolve: () => "node_modules",
});

plugin({
  name: "SCSS",
  setup(build) {
    return sassPlugin({
      ...pluginOpts,
      filter: /globalCss\.scss$/,
    }).setup({
      ...setupOpts(build),
      onLoad: (options, pathFn) => {
        const pathFnWrapper = async (path) => {
          const pathResult = await pathFn(path);
          return {
            ...pathResult,
            loader: "object",
            exports: {
              default: {
                _getCss: () => pathResult.contents,
              },
            },
          };
        };
        return build.onLoad(options, pathFnWrapper);
      },
    });
  },
});

plugin({
  name: "SCSS Modules",
  setup(build) {
    return sassPlugin({
      ...pluginOpts,
      filter: /^((?!globalCss).)*\.scss$/,
      transform: postcssModules({}, [
        postcssUrl({
          url: "inline",
          maxSize: 4,
          fallback: (asset) => assetFromPath(asset.absolutePath),
        }),
      ]),
      // we're using type: "style" instead of "css" because "css" outputs a
      // css-chunk: path that Bun doesn't know to run through esbuild a second
      // time. "style", on the other hand, outputs the actual CSS as a string.
      type: "style",
    }).setup({
      ...setupOpts(build),
      onLoad: (options, pathFn) => {
        const pathFnWrapper = async (path) => {
          const pathResult = await pathFn(path);
          return {
            ...pathResult,
            // because we're using "style" instead of "css", we have to remove
            // all browser-specific code and return the CSS in a function
            // instead
            contents: pathResult?.contents.replace(
              'document.head\n    .appendChild(document.createElement("style"))\n    .appendChild(document.createTextNode(css));\nexport {css};\nexport default {',
              "export default {\n_getCss: () => css,\n"
            ),
          };
        };
        return build.onLoad(options, pathFnWrapper);
      },
    });
  },
});
