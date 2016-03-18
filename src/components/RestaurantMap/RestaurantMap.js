import React, { PropTypes } from 'react';
import { Provider } from 'react-redux';
import ContextHolder from '../../core/ContextHolder';
import RestaurantContainer from '../../containers/RestaurantContainer';
import { GoogleMapLoader, GoogleMap, Marker, InfoWindow } from 'react-google-maps';
import { canUseDOM } from 'fbjs/lib/ExecutionEnvironment';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './RestaurantMap.scss';

let google;
if (canUseDOM) {
  google = window.google;
} else {
  google = { maps: { SymbolPath: {} } };
}

const RestaurantMap = ({ latLng, items, mapUi, handleMarkerClick, handleMarkerClose }, context) => (
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
          />
          {items.map((item, index) => {
            const length = item.votes.length;
            const label = {
              fontWeight: 'bold',
              text: ' '
            };
            if (item.votes.length > 9) {
              label.text = '✔';
            } else if (item.votes.length > 0) {
              label.text = String(length);
            }

            const ref = `marker_${index}`;

            const mapUiItem = mapUi[item.id] || {};

            const boundHandleMarkerClick = handleMarkerClick.bind(this, item.id);

            const renderInfoWindow = () => {
              const boundHandleMarkerClose = handleMarkerClose.bind(this, item.id);

              return (
                <InfoWindow
                  key={`${ref}_info_window`}
                  onCloseclick={boundHandleMarkerClose}
                >
                  <ContextHolder context={context}>
                    <Provider store={context.store}>
                      <RestaurantContainer
                        id={item.id}
                        name={item.name}
                        address={item.address}
                        votes={item.votes}
                        tags={item.tags}
                      />
                    </Provider>
                  </ContextHolder>
                </InfoWindow>
              );
            };

            return (
              <Marker
                position={{ lat: item.lat, lng: item.lng }}
                label={label}
                key={index}
                title={item.name}
                onClick={boundHandleMarkerClick}
              >
                {mapUiItem.showInfoWindow ? renderInfoWindow() : null}
              </Marker>
            );
          })}
        </GoogleMap>
      }
    />
  </section>
);

RestaurantMap.contextTypes = {
  insertCss: PropTypes.func,
  store: PropTypes.object
};

RestaurantMap.propTypes = {
  handleMarkerClick: PropTypes.func.isRequired,
  handleMarkerClose: PropTypes.func.isRequired,
  items: PropTypes.array.isRequired,
  latLng: PropTypes.object.isRequired,
  mapUi: PropTypes.object
};

export default withStyles(RestaurantMap, s);
