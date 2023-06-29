/* eslint-disable max-classes-per-file */

import PropTypes from "prop-types";
import React, { Component, Suspense, lazy } from "react";
import { VNode } from "preact";
import withStyles from "isomorphic-style-loader/withStyles";
import { GOOGLE_MAP_ZOOM } from "../../constants";
import googleMapOptions from "../../helpers/googleMapOptions";
import { AppContext, InfoWindow, LatLng, Restaurant } from "../../interfaces";
import RestaurantMarkerContainer from "../RestaurantMarker/RestaurantMarkerContainer";
import RestaurantMapSettingsContainer from "../RestaurantMapSettings/RestaurantMapSettingsContainer";
import GoogleInfoWindowContainer from "../GoogleInfoWindow/GoogleInfoWindowContainer";
import HereMarker from "../HereMarker/HereMarker";
import TempMarker from "../TempMarker/TempMarker";
import s from "./RestaurantMap.scss";
import GoogleMapsLoaderContext from "../GoogleMapsLoaderContext/GoogleMapsLoaderContext";

const GoogleMap = lazy(
  () => import(/* webpackChunkName: 'map' */ "google-map-react")
);

interface RestaurantMapProps {
  infoWindow: InfoWindow;
  items: { id: number; lat: number; lng: number }[];
  latLng: LatLng;
  center?: LatLng;
  defaultZoom?: number;
  tempMarker?: { latLng: LatLng };
  newlyAddedRestaurant?: Restaurant;
  clearCenter: () => void;
  mapClicked: () => void;
  showGoogleInfoWindow: (event: google.maps.IconMouseEvent) => void;
  showNewlyAddedInfoWindow: () => void;
  showPOIs: boolean;
}

class RestaurantMap extends Component<RestaurantMapProps> {
  context: AppContext;

  map: google.maps.Map;

  static contextTypes = {
    insertCss: PropTypes.func.isRequired,
    store: PropTypes.object.isRequired,
    pathname: PropTypes.string.isRequired,
    query: PropTypes.object,
  };

  static defaultProps = {
    center: undefined,
    defaultZoom: GOOGLE_MAP_ZOOM,
    tempMarker: undefined,
    newlyAddedRestaurant: undefined,
  };

  componentDidMount() {
    this.props.clearCenter();
  }

  componentDidUpdate() {
    if (this.props.center !== undefined) {
      this.props.clearCenter();

      if (this.map && this.props.tempMarker === undefined) {
        // offset by infowindow height after recenter
        setTimeout(() => {
          this.map.panBy(0, -100);
        });
      }
    }
    if (this.props.newlyAddedRestaurant !== undefined) {
      this.props.showNewlyAddedInfoWindow();
    }
  }

  setMap = ({ map }: { map: google.maps.Map }) => {
    this.map = map;
    map.addListener("click", (event: google.maps.IconMouseEvent) => {
      if (event.placeId && event.latLng) {
        event.stop();
        this.props.showGoogleInfoWindow(event);
      }
    });
  };

  render() {
    const {
      center,
      defaultZoom,
      infoWindow,
      items,
      latLng,
      mapClicked,
      showPOIs,
      tempMarker,
    } = this.props;

    let tempMarkerComponent: VNode;
    if (tempMarker !== undefined) {
      tempMarkerComponent = <TempMarker {...tempMarker.latLng} />;
    }

    let googleInfoWindow: VNode;
    if ("placeId" in infoWindow && infoWindow.placeId && infoWindow.latLng) {
      googleInfoWindow = (
        <GoogleInfoWindowContainer
          map={this.map}
          placeId={infoWindow.placeId}
          {...infoWindow.latLng}
        />
      );
    }

    return (
      <section className={s.root}>
        <GoogleMapsLoaderContext.Consumer>
          {({ loader }) =>
            loader ? (
              <Suspense fallback={null}>
                <GoogleMap
                  defaultZoom={defaultZoom || GOOGLE_MAP_ZOOM}
                  defaultCenter={latLng}
                  center={center}
                  googleMapLoader={() =>
                    loader.load().then((google) => google.maps)
                  }
                  margin={[100, 0, 0, 0]}
                  options={googleMapOptions(showPOIs)}
                  onGoogleApiLoaded={this.setMap}
                  onClick={mapClicked}
                  yesIWantToUseGoogleMapApiInternals
                >
                  <HereMarker lat={latLng.lat} lng={latLng.lng} />
                  {googleInfoWindow}
                  {tempMarkerComponent}
                  {items.map((item, index) => (
                    <RestaurantMarkerContainer
                      lat={item.lat}
                      lng={item.lng}
                      key={`restaurantMarkerContainer_${item.id}`}
                      id={item.id}
                      index={index}
                      baseZIndex={items.length}
                      googleApiKey={loader.apiKey}
                      store={this.context.store}
                      insertCss={this.context.insertCss}
                      pathname={this.context.pathname}
                      query={this.context.query}
                    />
                  ))}
                </GoogleMap>
              </Suspense>
            ) : null
          }
        </GoogleMapsLoaderContext.Consumer>
        <div className={s.mapSettingsContainer}>
          <RestaurantMapSettingsContainer map={this.map} />
        </div>
      </section>
    );
  }
}

export default withStyles(s)(RestaurantMap);
