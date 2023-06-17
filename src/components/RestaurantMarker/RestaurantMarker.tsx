import React from "react";
import { canUseDOM } from "fbjs/lib/ExecutionEnvironment";
import withStyles from "isomorphic-style-loader/withStyles";
import { AppContext, Restaurant } from "../../interfaces";
import App from "../App";
import RestaurantContainer from "../Restaurant/RestaurantContainer";
import s from "./RestaurantMarker.scss";

let google = { maps: { Marker: { MAX_ZINDEX: 1000000 } } };
if (canUseDOM) {
  google = window.google || google;
}

interface InnerRestaurantMarkerProps {
  restaurant: Restaurant;
  decided: boolean;
  index: number;
  baseZIndex: number;
  handleMarkerClick: () => void;
  showInfoWindow: boolean;
}

const InnerRestaurantMarker = ({
  restaurant,
  decided,
  index,
  baseZIndex,
  handleMarkerClick,
  showInfoWindow,
}: InnerRestaurantMarkerProps) => {
  const length = restaurant.votes.length;
  let label = "";

  // place markers over default markers
  // place markers higher based on vote length
  // place markers lower based on how far down they are in the list
  // add item length so index doesn't dip below MAX_ZINDEX
  const zIndex =
    google.maps.Marker.MAX_ZINDEX +
    restaurant.votes.length +
    -index +
    baseZIndex;

  if (restaurant.votes.length > 99 || decided) {
    label = "✔";
  } else if (restaurant.votes.length > 0) {
    label = String(length);
  }

  const ref = `marker_${index}`;

  const renderInfoWindow = () => (
    <div
      className={s.infoWindow}
      style={{ zIndex: zIndex * 2 }}
      key={`infoWindow_${ref}`}
    >
      <RestaurantContainer id={restaurant.id} />
    </div>
  );

  return (
    <div
      className={`${s.root} ${
        restaurant.votes.length > 0 || decided ? s.voted : ""
      }`}
      data-marker
    >
      {showInfoWindow ? renderInfoWindow() : null}
      <button
        key={index}
        tabIndex={-1}
        title={restaurant.name}
        onClick={handleMarkerClick}
        className={s.marker}
        style={{ zIndex }}
        type="button"
      >
        <span className={s.label}>{label}</span>
      </button>
    </div>
  );
};

const StyledRestaurantMarker = withStyles(s)(InnerRestaurantMarker);

export interface RestaurantMarkerProps extends AppContext {
  restaurant: Restaurant;
}

const RestaurantMarker = ({ restaurant, ...props }: RestaurantMarkerProps) => {
  const context = {
    googleApiKey: props.googleApiKey,
    insertCss: props.insertCss,
    store: props.store,
    pathname: props.pathname,
    query: props.query,
  };

  return (
    <App context={context}>
      <StyledRestaurantMarker
        lat={restaurant.lat}
        lng={restaurant.lng}
        restaurant={restaurant}
        {...props}
      />
    </App>
  );
};

export default RestaurantMarker;
