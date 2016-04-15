import React, { PropTypes } from 'react';
import RestaurantMarkerContainer from '../../containers/RestaurantMarkerContainer';
import RestaurantMapSettingsContainer from '../../containers/RestaurantMapSettingsContainer';
import { GoogleMapLoader, GoogleMap, Marker } from 'react-google-maps';
import { canUseDOM } from 'fbjs/lib/ExecutionEnvironment';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './RestaurantMap.scss';

let google;
if (canUseDOM) {
  google = window.google;
} else {
  google = { maps: { SymbolPath: {} } };
}

const RestaurantMap = ({ latLng, items }) => (
  <section className={s.root}>
    <GoogleMapLoader
      containerElement={
        <div
          style={{
            height: '100%'
          }}
        />
      }
      googleMapElement={
        <GoogleMap
          defaultZoom={16}
          defaultCenter={latLng}
          defaultOptions={{
            scrollwheel: false
          }}
        >
          <Marker
            clickable={false}
            position={latLng}
            icon={{
              fillColor: 'pink',
              fillOpacity: 1,
              path: google.maps.SymbolPath.CIRCLE,
              scale: 6,
              strokeWeight: 2
            }}
            title="You are here"
            zIndex={0}
          />
          {items.map((id, index) =>
            <RestaurantMarkerContainer
              key={`restaurantMarkerContainer_${id}`}
              id={id}
              index={index}
              baseZIndex={items.length}
            />
          )}
          <div className={s.mapSettingsContainer}>
            <RestaurantMapSettingsContainer />
          </div>
        </GoogleMap>
      }
    />
  </section>
);

RestaurantMap.propTypes = {
  items: PropTypes.array.isRequired,
  latLng: PropTypes.object.isRequired
};

export default withStyles(RestaurantMap, s);
