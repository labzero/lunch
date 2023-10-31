export default (path: string) => {
  // use Webpack's generated asset URLs when loading images
  const assetManifest = require("../../../build/asset-manifest.json");
  return assetManifest[path.replace(`${process.cwd()}/`, "")];
};
