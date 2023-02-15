import PropTypes from 'prop-types';
import React, { Component } from 'react';
import withStyles from 'isomorphic-style-loader/withStyles';
import { GOOGLE_MAP_ZOOM } from '../../constants';
import googleMapOptions from '../../helpers/googleMapOptions';
import loadComponent from '../../helpers/loadComponent';
import RestaurantMarkerContainer from '../RestaurantMarker/RestaurantMarkerContainer';
import RestaurantMapSettingsContainer from '../RestaurantMapSettings/RestaurantMapSettingsContainer';
import GoogleInfoWindowContainer from '../GoogleInfoWindow/GoogleInfoWindowContainer';
import HereMarker from '../HereMarker';
import TempMarker from '../TempMarker';
import s from './RestaurantMap.scss';
import GoogleMapsLoaderContext from '../GoogleMapsLoaderContext/GoogleMapsLoaderContext';

let GoogleMap = () => null;

class RestaurantMap extends Component {
  static contextTypes = {
    fetch: PropTypes.func.isRequired,
    insertCss: PropTypes.func.isRequired,
    store: PropTypes.object.isRequired,
    pathname: PropTypes.string.isRequired,
    query: PropTypes.object,
  };

  static propTypes = {
    infoWindow: PropTypes.object.isRequired,
    items: PropTypes.array.isRequired,
    latLng: PropTypes.object.isRequired,
    center: PropTypes.shape({
      lat: PropTypes.number.isRequired,
      lng: PropTypes.number.isRequired,
    }),
    defaultZoom: PropTypes.number,
    tempMarker: PropTypes.object,
    newlyAddedRestaurant: PropTypes.object,
    clearCenter: PropTypes.func.isRequired,
    mapClicked: PropTypes.func.isRequired,
    showGoogleInfoWindow: PropTypes.func.isRequired,
    showNewlyAddedInfoWindow: PropTypes.func.isRequired,
    showPOIs: PropTypes.bool.isRequired,
  };

  static defaultProps = {
    center: undefined,
    defaultZoom: GOOGLE_MAP_ZOOM,
    tempMarker: undefined,
    newlyAddedRestaurant: undefined,
  };

  componentDidMount() {
    this.props.clearCenter();
    loadComponent(() => require.ensure(
      [],
      (require) => require('google-map-react').default,
      'map'
    )).then((map) => {
      GoogleMap = map;
      this.forceUpdate();
    });
  }

  componentDidUpdate() {
    if (this.props.center !== undefined) {
      this.props.clearCenter();

      if (this.props.tempMarker === undefined) {
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

  setMap = ({ map }) => {
    this.map = map;
    map.addListener('click', (event) => {
      if (event.placeId) {
        event.stop();
        const defaultPrevented = event.ya && event.ya.defaultPrevented;
        if (!defaultPrevented) {
          this.props.showGoogleInfoWindow(event);
        }
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

    let tempMarkerComponent;
    if (tempMarker !== undefined) {
      tempMarkerComponent = <TempMarker {...tempMarker.latLng} />;
    }

    let googleInfoWindow;
    if (infoWindow.placeId && infoWindow.latLng) {
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
          {({ loader }) => loader ? (
            <GoogleMap
              defaultZoom={defaultZoom || GOOGLE_MAP_ZOOM}
              defaultCenter={latLng}
              center={center}
              googleMapLoader={() => loader.load().then(google => google.maps)}
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
                  fetch={this.context.fetch}
                  insertCss={this.context.insertCss}
                  pathname={this.context.pathname}
                  query={this.context.query}
                />
              ))}
            </GoogleMap>
          ) : null}
        </GoogleMapsLoaderContext.Consumer>
        <div className={s.mapSettingsContainer}>
          <RestaurantMapSettingsContainer map={this.map} />
        </div>
      </section>
    );
  }
}

export default withStyles(s)(RestaurantMap);
