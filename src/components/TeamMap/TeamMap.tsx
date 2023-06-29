import React, { Component, Suspense, lazy } from "react";
import withStyles from "isomorphic-style-loader/withStyles";
import HereMarker from "../HereMarker/HereMarker";
import { GOOGLE_MAP_ZOOM } from "../../constants";
import googleMapOptions from "../../helpers/googleMapOptions";
import { LatLng } from "../../interfaces";
import s from "./TeamMap.scss";
import GoogleMapsLoaderContext from "../GoogleMapsLoaderContext/GoogleMapsLoaderContext";

const GoogleMap = lazy(
  () => import(/* webpackChunkName: 'map' */ "google-map-react")
);

export interface TeamMapProps {
  center?: LatLng;
  clearCenter: () => void;
  defaultCenter: LatLng;
  setCenter: (center: { lat: number; lng: number }) => void;
}

class TeamMap extends Component<TeamMapProps> {
  map: google.maps.Map;

  static defaultProps = {
    center: undefined,
  };

  componentDidMount() {
    this.props.clearCenter();
  }

  setMap = ({ map }: { map: google.maps.Map }) => {
    this.map = map;
    this.map.addListener("bounds_changed", () => {
      const center = map.getCenter();
      if (center) {
        this.props.setCenter({
          lat: center.lat(),
          lng: center.lng(),
        });
      }
    });
  };

  render() {
    const { center, defaultCenter } = this.props;

    return (
      <div className={s.root}>
        <GoogleMapsLoaderContext.Consumer>
          {({ loader }) =>
            loader ? (
              <Suspense fallback={null}>
                <GoogleMap
                  center={center}
                  defaultZoom={GOOGLE_MAP_ZOOM}
                  defaultCenter={defaultCenter}
                  googleMapLoader={() =>
                    loader.load().then((google) => google.maps)
                  }
                  onGoogleApiLoaded={this.setMap}
                  options={googleMapOptions()}
                  yesIWantToUseGoogleMapApiInternals
                />
              </Suspense>
            ) : null
          }
        </GoogleMapsLoaderContext.Consumer>
        <div className={s.hereCenterer}>
          <HereMarker />
        </div>
      </div>
    );
  }
}

export default withStyles(s)(TeamMap);
