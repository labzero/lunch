import { Loader } from "@googlemaps/js-api-loader";
import { createContext } from "react";

export interface IGoogleMapsLoaderContext {
  loader?: Loader;
}

const GoogleMapsLoaderContext = createContext<IGoogleMapsLoaderContext>({});

export default GoogleMapsLoaderContext;
