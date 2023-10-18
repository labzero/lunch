/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

/* eslint-disable no-nested-ternary */

import fs from "fs";
import path from "path";
import webpack from "webpack";
import WebpackAssetsManifest from "webpack-assets-manifest";
import nodeExternals from "webpack-node-externals";
import { BundleAnalyzerPlugin } from "webpack-bundle-analyzer";
// import { InjectManifest } from "workbox-webpack-plugin";
import ForkTsCheckerWebpackPlugin from "fork-ts-checker-webpack-plugin";
import ReactRefreshWebpackPlugin from "@pmmmwh/react-refresh-webpack-plugin";
import overrideRules from "./lib/overrideRules";

const ROOT_DIR = path.resolve(__dirname, "..");
const resolvePath = (...args) => path.resolve(ROOT_DIR, ...args);
const SRC_DIR = resolvePath("src");
const BUILD_DIR = resolvePath("build");

const isDebug = !process.argv.includes("--release");
const isVerbose = process.argv.includes("--verbose");
const isAnalyze =
  process.argv.includes("--analyze") || process.argv.includes("--analyse");

const reScript = /\.(js|jsx|mjs|ts|tsx)$/;
const reStyle = /\.(css|less|styl|scss|sass|sss)$/;
const reImage = /\.(bmp|gif|jpg|jpeg|png|svg)$/;
const staticAssetName = isDebug
  ? "[path][name].[ext]?[hash:8]"
  : "[hash:8].[ext]";

//
// Common configuration chunk to be used for both
// client-side (client.tsx) and server-side (server.js) bundles
// -----------------------------------------------------------------------------

const config = {
  context: ROOT_DIR,

  mode: isDebug ? "development" : "production",

  output: {
    path: resolvePath(BUILD_DIR, "public/assets"),
    publicPath: "/assets/",
    pathinfo: isVerbose,
    filename: isDebug ? "[name].js" : "[name].[chunkhash:8].js",
    chunkFilename: isDebug
      ? "[name].chunk.js"
      : "[name].[chunkhash:8].chunk.js",
    devtoolModuleFilenameTemplate: (info) =>
      path.resolve(info.absoluteResourcePath),
  },

  resolve: {
    extensions: [".tsx", ".ts", ".js"],

    // Add support for TypeScripts fully qualified ESM imports.
    extensionAlias: {
      ".js": [".js", ".ts"],
      ".cjs": [".cjs", ".cts"],
      ".mjs": [".mjs", ".mts"],
    },
    // Allow absolute paths in imports, e.g. import Button from 'components/Button'
    // Keep in sync with .flowconfig and .eslintrc
    modules: ["node_modules", "src"],

    // Do not replace node globals with polyfills
    // https://webpack.js.org/configuration/node/
    fallback: {
      buffer: false,
      console: false,
      crypto: false,
      process: false,
    },
  },

  module: {
    // Make missing exports an error instead of warning
    strictExportPresence: true,

    rules: [
      {
        test: /\.tsx?$/,
        use: "ts-loader",
        exclude: /node_modules/,
      },
      // Rules for Style Sheets
      {
        test: reStyle,
        rules: [
          // Convert CSS into JS module
          {
            issuer: { not: [reStyle] },
            use: "isomorphic-style-loader",
          },

          // Process external/third-party styles
          {
            exclude: SRC_DIR,
            loader: "css-loader",
            options: {
              esModule: false,
              sourceMap: isDebug,
            },
          },

          // Process internal/project styles (from src folder)
          {
            test: /^((?!globalCss).)*\.(css|scss|less|sss)$/,
            include: SRC_DIR,
            loader: "css-loader",
            options: {
              esModule: false,
              // CSS Loader https://github.com/webpack/css-loader
              importLoaders: 1,
              sourceMap: isDebug,
              // CSS Modules https://github.com/css-modules/css-modules
              modules: {
                // eslint-disable-next-line no-nested-ternary
                localIdentName:
                  process.env.NODE_ENV === "test"
                    ? "[name]-[local]"
                    : isDebug
                    ? "[name]-[local]-[hash:base64:5]"
                    : "[hash:base64:5]",
              },
            },
          },

          // Process internal/project styles (from src folder)
          {
            test: /globalCss\.scss$/,
            include: SRC_DIR,
            loader: "css-loader",
            options: {
              esModule: false,
              // CSS Loader https://github.com/webpack/css-loader
              importLoaders: 1,
              sourceMap: isDebug,
              // CSS Modules https://github.com/css-modules/css-modules
              modules: {
                localIdentName: "[local]",
              },
            },
          },

          // Compile Less to CSS
          // https://github.com/webpack-contrib/less-loader
          // Install dependencies before uncommenting: yarn add --dev less-loader less
          // {
          //   test: /\.less$/,
          //   loader: 'less-loader',
          // },

          // Compile Sass to CSS
          // https://github.com/webpack-contrib/sass-loader
          // Install dependencies before uncommenting: yarn add --dev sass-loader node-sass,
          {
            test: /\.scss$/,
            loader: "postcss-loader",
            options: {
              postcssOptions: {
                config: "./tools/postcss.sass.config.js",
              },
            },
          },
          {
            test: /\.scss$/,
            use: [
              {
                loader: "sass-loader",
              },
            ],
          },
        ],
      },

      // Rules for images
      {
        test: reImage,
        oneOf: [
          // Inline lightweight images into CSS
          {
            issuer: reStyle,
            oneOf: [
              // Inline lightweight SVGs as UTF-8 encoded DataUrl string
              {
                test: /\.svg$/,
                loader: "svg-url-loader",
                options: {
                  esModule: false,
                  name: staticAssetName,
                  limit: 4096, // 4kb
                },
              },

              // Inline lightweight images as Base64 encoded DataUrl string
              {
                loader: "url-loader",
                options: {
                  esModule: false,
                  name: staticAssetName,
                  limit: 4096, // 4kb
                },
              },
            ],
          },

          // Or return public URL to image resource
          {
            loader: "file-loader",
            options: {
              esModule: false,
              name: staticAssetName,
            },
          },
        ],
      },

      // Convert plain text into JS module
      {
        test: /\.txt$/,
        loader: "raw-loader",
      },

      // Convert Markdown into HTML
      {
        test: /\.md$/,
        loader: path.resolve(__dirname, "./lib/markdown-loader.js"),
      },

      // Return public URL for all assets unless explicitly excluded
      // DO NOT FORGET to update `exclude` list when you adding a new loader
      {
        exclude: [reScript, reStyle, reImage, /\.json$/, /\.txt$/, /\.md$/],
        loader: "file-loader",
        options: {
          name: staticAssetName,
        },
      },

      // Exclude dev modules from production build
      ...(isDebug
        ? []
        : [
            {
              test: resolvePath(
                "node_modules/react-deep-force-update/lib/index.js"
              ),
              loader: "null-loader",
            },
          ]),
    ],
  },

  plugins: [
    new ForkTsCheckerWebpackPlugin(),
    isDebug &&
      process.env.NODE_ENV !== "test" &&
      new webpack.HotModuleReplacementPlugin(),
    isDebug &&
      process.env.NODE_ENV !== "test" &&
      new ReactRefreshWebpackPlugin({
        overlay: {
          sockIntegration: "whm",
        },
      }),
  ].filter(Boolean),

  // Don't attempt to continue if there are any errors.
  bail: !isDebug,

  cache: isDebug,

  // Specify what bundle information gets displayed
  // https://webpack.js.org/configuration/stats/
  stats: "errors-warnings",

  // Choose a developer tool to enhance debugging
  // https://webpack.js.org/configuration/devtool/#devtool
  devtool: isDebug ? "inline-source-map" : "source-map",
};

//
// Configuration for the client-side bundle (client.tsx)
// -----------------------------------------------------------------------------

const clientConfig = {
  ...config,

  name: "client",
  target: "web",

  entry: {
    client: "./src/client.tsx",
  },

  plugins: [
    ...config.plugins,
    // Define free variables
    // https://webpack.js.org/plugins/define-plugin/
    new webpack.DefinePlugin({
      "process.env.BROWSER": true,
      __DEV__: isDebug,
    }),

    // Emit a file with assets paths
    // https://github.com/webdeveric/webpack-assets-manifest#options
    new WebpackAssetsManifest({
      output: `${BUILD_DIR}/asset-manifest.json`,
      publicPath: true,
      writeToDisk: true,
      customize: ({ key, value }) => {
        // You can prevent adding items to the manifest by returning false.
        if (key.toLowerCase().endsWith(".map")) return false;
        return { key, value };
      },
      done: (manifest, stats) => {
        // Write chunk-manifest.json.json
        const chunkFileName = `${BUILD_DIR}/chunk-manifest.json`;
        try {
          const fileFilter = (file) => !file.endsWith(".map");
          const addPath = (file) => manifest.getPublicPath(file);
          const chunkFiles = stats.compilation.chunkGroups.reduce(
            (acc, c) => ({
              ...acc,
              [c.name]: [
                ...(acc[c.name] || []),
                ...c.chunks.reduce(
                  (files, cc) => [
                    ...files,
                    ...Array.from(cc.files).filter(fileFilter).map(addPath),
                  ],
                  []
                ),
              ],
            }),
            Object.create(null)
          );
          fs.writeFileSync(chunkFileName, JSON.stringify(chunkFiles, null, 2));
        } catch (err) {
          console.error(`ERROR: Cannot write ${chunkFileName}: `, err);
          if (!isDebug) process.exit(1);
        }
      },
    }),

    ...(isDebug
      ? []
      : [
          // Webpack Bundle Analyzer
          // https://github.com/th0r/webpack-bundle-analyzer
          ...(isAnalyze ? [new BundleAnalyzerPlugin()] : []),
        ]),

    // TODO: this makes Bun die
    /* new InjectManifest({
      swSrc: "./src/service-worker.js",
      swDest: resolvePath(BUILD_DIR, "public/service-worker.js"),
    }), */
  ],

  // Move modules that occur in multiple entry chunks to a new entry chunk (the commons chunk).
  optimization: {
    sideEffects: false,
    splitChunks: {
      cacheGroups: {
        commons: {
          chunks: "initial",
          test: /[\\/]node_modules[\\/]/,
          name: "vendors",
        },
      },
    },
  },

  // Some libraries import Node modules but don't use them in the browser.
  // Tell Webpack to provide empty mocks for them so importing them works.
  // https://webpack.js.org/configuration/node/
  // https://github.com/webpack/node-libs-browser/tree/master/mock
  resolve: {
    ...config.resolve,
    fallback: {
      ...config.resolve.fallback,
      fs: "empty",
      net: "empty",
      tls: "empty",
    },
  },
};

//
// Configuration for the server-side bundle (server.js)
// -----------------------------------------------------------------------------

const serverConfig = {
  ...config,

  name: "server",
  target: "node",

  entry: {
    server: "./src/server.tsx",
  },

  output: {
    ...config.output,
    path: BUILD_DIR,
    filename: "[name].js",
    chunkFilename: "chunks/[name].js",
    libraryTarget: "commonjs2",
  },

  // Webpack mutates resolve object, so clone it to avoid issues
  // https://github.com/webpack/webpack/issues/4817
  resolve: {
    ...config.resolve,
  },

  module: {
    ...config.module,

    rules: overrideRules(config.module.rules, (rule) => {
      // Override paths to static assets
      if (
        rule.loader === "file-loader" ||
        rule.loader === "url-loader" ||
        rule.loader === "svg-url-loader"
      ) {
        return {
          ...rule,
          options: {
            ...rule.options,
            name: `public/assets/${rule.options.name}`,
            publicPath: (url) => url.replace(/^public/, ""),
          },
        };
      }

      return rule;
    }),
  },

  externals: [
    "./chunk-manifest.json",
    "./asset-manifest.json",
    nodeExternals({
      allowlist: [reStyle, reImage],
    }),
  ],

  plugins: [
    ...config.plugins,
    // Define free variables
    // https://webpack.js.org/plugins/define-plugin/
    new webpack.DefinePlugin({
      // eslint-disable-next-line no-nested-ternary
      "process.env.NODE_ENV":
        process.env.NODE_ENV === "test"
          ? '"test"'
          : isDebug
          ? '"development"'
          : '"production"',
      "process.env.BROWSER": false,
      __DEV__: isDebug,
    }),

    // Adds a banner to the top of each generated chunk
    // https://webpack.js.org/plugins/banner-plugin/
    new webpack.BannerPlugin({
      banner: 'require("source-map-support").install();',
      raw: true,
      entryOnly: false,
    }),
  ],

  // Do not replace node globals with polyfills
  // https://webpack.js.org/configuration/node/
  node: {
    global: false,
    __filename: false,
    __dirname: false,
  },
};

export default [clientConfig, serverConfig];
