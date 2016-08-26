import React, { PropTypes } from 'react';
import { canUseDOM } from 'fbjs/lib/ExecutionEnvironment';
import ContextHolder from '../../core/ContextHolder';
import { Provider } from 'react-redux';
import RestaurantContainer from '../../containers/RestaurantContainer';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './RestaurantMarker.scss';

let google = { maps: { Marker: { MAX_ZINDEX: 1000000 } } };
if (canUseDOM) {
  google = window.google || google;
}

const InnerRestaurantMarker = ({
  restaurant,
  decided,
  index,
  baseZIndex,
  handleMarkerClick,
  showInfoWindow
}) => {
  const length = restaurant.votes.length;
  let label = '';

  // place markers over default markers
  // place markers higher based on vote length
  // place markers lower based on how far down they are in the list
  // add item length so index doesn't dip below MAX_ZINDEX
  const zIndex =
      google.maps.Marker.MAX_ZINDEX
      + restaurant.votes.length
      - index
      + baseZIndex;

  if (restaurant.votes.length > 99 || decided) {
    label = '✔';
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
      <RestaurantContainer
        id={restaurant.id}
      />
    </div>
  );

  return (
    <div
      className={`${s.root} ${restaurant.votes.length > 0 || decided ? s.voted : ''}`}
      data-marker
    >
      {showInfoWindow ? renderInfoWindow() : null}
      <div
        key={index}
        title={restaurant.name}
        onClick={handleMarkerClick}
        className={s.marker}
        style={{ zIndex }}
      >
        <span className={s.label}>
          {label}
        </span>
      </div>
    </div>
  );
};

InnerRestaurantMarker.propTypes = {
  restaurant: PropTypes.object.isRequired,
  decided: PropTypes.bool.isRequired,
  index: PropTypes.number.isRequired,
  baseZIndex: PropTypes.number.isRequired,
  showInfoWindow: PropTypes.bool.isRequired,
  handleMarkerClick: PropTypes.func.isRequired
};

const StyledRestaurantMarker = withStyles(s)(InnerRestaurantMarker);

const RestaurantMarker = ({
  restaurant,
  ...props
}) => {
  const context = {
    insertCss: props.insertCss,
    store: props.store
  };

  return (
    <ContextHolder context={context}>
      <Provider store={context.store}>
        <StyledRestaurantMarker
          lat={restaurant.lat}
          lng={restaurant.lng}
          restaurant={restaurant}
          {...props}
        />
      </Provider>
    </ContextHolder>
  );
};

RestaurantMarker.propTypes = {
  store: PropTypes.object.isRequired,
  insertCss: PropTypes.func.isRequired,
  restaurant: PropTypes.object.isRequired
};

export default RestaurantMarker;
