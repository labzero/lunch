import PropTypes from "prop-types";
import React, { Component, Suspense, lazy } from "react";
import withStyles from "isomorphic-style-loader/withStyles";
import HereMarker from "../HereMarker";
import { GOOGLE_MAP_ZOOM } from "../../constants";
import googleMapOptions from "../../helpers/googleMapOptions";
import s from "./TeamMap.scss";
import GoogleMapsLoaderContext from "../GoogleMapsLoaderContext/GoogleMapsLoaderContext";

const GoogleMap = lazy(() =>
  import(/* webpackChunkName: 'map' */ "google-map-react")
);

class TeamMap extends Component {
  static propTypes = {
    center: PropTypes.shape({
      lat: PropTypes.number.isRequired,
      lng: PropTypes.number.isRequired,
    }),
    clearCenter: PropTypes.func.isRequired,
    defaultCenter: PropTypes.shape({
      lat: PropTypes.number.isRequired,
      lng: PropTypes.number.isRequired,
    }).isRequired,
    setCenter: PropTypes.func.isRequired,
  };

  static defaultProps = {
    center: undefined,
  };

  componentDidMount() {
    this.props.clearCenter();
  }

  setMap = ({ map }) => {
    this.map = map;
    this.map.addListener("bounds_changed", () => {
      const center = map.getCenter();
      this.props.setCenter({
        lat: center.lat(),
        lng: center.lng(),
      });
    });
  };

  render() {
    const { center, defaultCenter } = this.props;

    return (
      <div className={s.root}>
        <GoogleMapsLoaderContext.Consumer>
          {({ loader }) => (
            <Suspense>
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
          )}
        </GoogleMapsLoaderContext.Consumer>
        <div className={s.hereCenterer}>
          <HereMarker />
        </div>
      </div>
    );
  }
}

export default withStyles(s)(TeamMap);
