import { plugin } from "bun";
import assetFromPath from "./helpers/assetFromPath";

plugin({
  name: "Image",
  async setup(build) {
    build.onLoad({ filter: /\.(svg|png|jpg)$/ }, (args) => ({
      contents: `export default "${assetFromPath(args.path)}"`,
      loader: "js",
    }));
  },
});
