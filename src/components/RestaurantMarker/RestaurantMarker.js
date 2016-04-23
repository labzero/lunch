import React, { Component, PropTypes } from 'react';
import { canUseDOM } from 'fbjs/lib/ExecutionEnvironment';
import ContextHolder from '../../core/ContextHolder';
import { Provider } from 'react-redux';
import RestaurantContainer from '../../containers/RestaurantContainer';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './RestaurantMarker.scss';

let google;
if (canUseDOM) {
  google = window.google;
} else {
  google = { maps: { Marker: { MAX_ZINDEX: 1000000 } } };
}

const InnerRestaurantMarker = ({
  restaurant,
  index,
  baseZIndex,
  handleMarkerClose,
  handleMarkerClick,
  showInfoWindow
}) => {
  const length = restaurant.votes.length;
  let label = '';

  let zIndex;

  if (restaurant.votes.length > 0) {
    if (restaurant.votes.length > 9) {
      label = '✔';
    } else {
      label = String(length);
    }

    // place markers over default markers
    // place markers higher based on vote length
    // place markers lower based on how far down they are in the list
    // add item length so index doesn't dip below MAX_ZINDEX
    zIndex =
      google.maps.Marker.MAX_ZINDEX
      + restaurant.votes.length
      - index
      + baseZIndex;
  }

  const ref = `marker_${index}`;

  const renderInfoWindow = () => (
    <div
      key={`infoWindow_${ref}`}
      onCloseclick={handleMarkerClose}
    >
      <RestaurantContainer
        id={restaurant.id}
      />
    </div>
  );

  return (
    <div
      lat={restaurant.lat}
      lng={restaurant.lng}
      key={index}
      title={restaurant.name}
      onClick={handleMarkerClick}
      className={s.root}
      style={{ zIndex }}
    >
      {showInfoWindow ? renderInfoWindow() : null}
      {label}
    </div>
  );
};

InnerRestaurantMarker.propTypes = {
  restaurant: PropTypes.object.isRequired,
  index: PropTypes.number.isRequired,
  baseZIndex: PropTypes.number.isRequired,
  showInfoWindow: PropTypes.bool.isRequired,
  handleMarkerClick: PropTypes.func.isRequired,
  handleMarkerClose: PropTypes.func.isRequired
};

const StyledRestaurantMarker = withStyles(InnerRestaurantMarker, s);

const RestaurantMarker = ({
  ...props
}) => {
  const context = {
    insertCss: props.insertCss,
    store: props.store
  };

  return (
    <ContextHolder context={context}>
      <Provider store={context.store}>
        <StyledRestaurantMarker {...props} />
      </Provider>
    </ContextHolder>
  );
};

RestaurantMarker.propTypes = {
  store: PropTypes.object.isRequired,
  insertCss: PropTypes.func.isRequired
};

export default RestaurantMarker;
