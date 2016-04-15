import React, { PropTypes } from 'react';
import { canUseDOM } from 'fbjs/lib/ExecutionEnvironment';
import { Provider } from 'react-redux';
import ContextHolder from '../../core/ContextHolder';
import { Marker, InfoWindow } from 'react-google-maps';
import RestaurantContainer from '../../containers/RestaurantContainer';

let google;
if (canUseDOM) {
  google = window.google;
} else {
  google = { maps: { Marker: { MAX_ZINDEX: 1000000 } } };
}

export const RestaurantMarker = ({
  restaurant,
  index,
  baseZIndex,
  showInfoWindow,
  handleMarkerClick,
  handleMarkerClose,
  mapHolderRef
}, context) => {
  const length = restaurant.votes.length;
  const label = {
    fontWeight: 'bold',
    text: ' '
  };

  let zIndex;

  if (restaurant.votes.length > 0) {
    if (restaurant.votes.length > 9) {
      label.text = '✔';
    } else {
      label.text = String(length);
    }

    // place markers over default markers
    // place markers higher based on vote length
    // place markers lower based on how far down they are in the list
    // add item length so index doesn't dip below MAX_ZINDEX
    zIndex = google.maps.Marker.MAX_ZINDEX + restaurant.votes.length - index + baseZIndex.length;
  }

  const ref = `marker_${index}`;

  const renderInfoWindow = () => (
    <InfoWindow
      key={`infoWindow_${ref}`}
      onCloseclick={handleMarkerClose}
    >
      <ContextHolder context={context}>
        <Provider store={context.store}>
          <RestaurantContainer
            id={restaurant.id}
          />
        </Provider>
      </ContextHolder>
    </InfoWindow>
  );

  return (
    <Marker
      position={{ lat: restaurant.lat, lng: restaurant.lng }}
      label={label}
      key={index}
      title={restaurant.name}
      onClick={handleMarkerClick}
      zIndex={zIndex}
      mapHolderRef={mapHolderRef}
    >
      {showInfoWindow ? renderInfoWindow() : null}
    </Marker>
  );
};

RestaurantMarker.propTypes = {
  restaurant: PropTypes.object.isRequired,
  index: PropTypes.number.isRequired,
  baseZIndex: PropTypes.number.isRequired,
  showInfoWindow: PropTypes.bool.isRequired,
  handleMarkerClick: PropTypes.func.isRequired,
  handleMarkerClose: PropTypes.func.isRequired,
  mapHolderRef: PropTypes.object.isRequired
};

RestaurantMarker.contextTypes = {
  insertCss: PropTypes.func,
  store: PropTypes.object
};
