import React, { PropTypes } from 'react';
import RestaurantMarkerContainer from '../../containers/RestaurantMarkerContainer';
import RestaurantMapSettingsContainer from '../../containers/RestaurantMapSettingsContainer';
import GoogleMap from 'google-map-react';
import { canUseDOM } from 'fbjs/lib/ExecutionEnvironment';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './RestaurantMap.scss';

let google = { maps: { SymbolPath: {} } };
if (canUseDOM) {
  google = window.google || google;
}

const RestaurantMap = ({ latLng, items }, context) => (
  <section className={s.root}>
    <GoogleMap
      defaultZoom={16}
      defaultCenter={latLng}
      options={{
        scrollwheel: false
      }}
    >
      <div
        lat={latLng.lat}
        lng={latLng.lng}
        className={s.center}
        title="You are here"
      />
      {items.map((item, index) =>
        <RestaurantMarkerContainer
          lat={item.lat}
          lng={item.lng}
          key={`restaurantMarkerContainer_${item.id}`}
          id={item.id}
          index={index}
          baseZIndex={items.length}
          store={context.store}
          insertCss={context.insertCss}
        />
      )}
    </GoogleMap>
    <div className={s.mapSettingsContainer}>
      <RestaurantMapSettingsContainer />
    </div>
  </section>
);

RestaurantMap.contextTypes = {
  insertCss: PropTypes.func.isRequired,
  store: PropTypes.object.isRequired
};

RestaurantMap.propTypes = {
  items: PropTypes.array.isRequired,
  latLng: PropTypes.object.isRequired
};

export default withStyles(RestaurantMap, s);
