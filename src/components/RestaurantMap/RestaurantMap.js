import React, { PropTypes } from 'react';
import { Provider } from 'react-redux';
import ContextHolder from '../../core/ContextHolder';
import RestaurantContainer from '../../containers/RestaurantContainer';
import RestaurantMapSettingsContainer from '../../containers/RestaurantMapSettingsContainer';
import { GoogleMapLoader, GoogleMap, Marker, InfoWindow } from 'react-google-maps';
import { canUseDOM } from 'fbjs/lib/ExecutionEnvironment';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './RestaurantMap.scss';

let google;
if (canUseDOM) {
  google = window.google;
} else {
  google = { maps: { SymbolPath: {}, Marker: { MAX_ZINDEX: 1000000 } } };
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
            zIndex={0}
          />
          {items.map((item, index) => {
            if (!mapUi.showUnvoted && item.votes.length === 0) {
              return null;
            }

            const length = item.votes.length;
            const label = {
              fontWeight: 'bold',
              text: ' '
            };

            let zIndex;

            if (item.votes.length > 0) {
              if (item.votes.length > 9) {
                label.text = '✔';
              } else {
                label.text = String(length);
              }

              // place markers over default markers
              // place markers higher based on vote length
              // place markers lower based on how far down they are in the list
              // add item length so index doesn't dip below MAX_ZINDEX
              zIndex = google.maps.Marker.MAX_ZINDEX + item.votes.length - index + items.length;
            }

            const ref = `marker_${index}`;

            const mapUiItem = mapUi.markers[item.id] || {};

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
                zIndex={zIndex}
              >
                {mapUiItem.showInfoWindow ? renderInfoWindow() : null}
              </Marker>
            );
          })}
          <div className={s.mapSettingsContainer}>
            <RestaurantMapSettingsContainer />
          </div>
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
