import React, { Component, PropTypes } from 'react';
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

const HereMarker = () => (
  <div className={s.center} title="You are here" />
);

const TempMarker = () => (
  <div className={s.tempMarker}>
    <svg viewBox="-2 -2 19 19" width="19" height="19">
      <circle
        className={s.tempMarkerCircle}
        strokeWidth="2"
        stroke="#000"
        fill="transparent"
        strokeDasharray="2.95, 2.95"
        r="7.5"
        cx="7.5"
        cy="7.5"
      />
    </svg>
  </div>
);

class RestaurantMap extends Component {
  static contextTypes = {
    insertCss: PropTypes.func.isRequired,
    store: PropTypes.object.isRequired
  };

  static propTypes = {
    items: PropTypes.array.isRequired,
    latLng: PropTypes.object.isRequired,
    center: PropTypes.shape({
      lat: PropTypes.number.isRequired,
      lng: PropTypes.number.isRequired
    }),
    tempMarker: PropTypes.object,
    newlyAddedRestaurant: PropTypes.object,
    clearCenter: PropTypes.func.isRequired,
    mapClicked: PropTypes.func.isRequired,
    showNewlyAddedInfoWindow: PropTypes.func.isRequired
  };

  componentDidMount() {
    this._root.addEventListener('touchmove', event => {
      // prevent window from scrolling
      event.preventDefault();
    });
  }

  componentWillReceiveProps(nextProps) {
    if (nextProps.center !== undefined) {
      this.props.clearCenter();

      if (nextProps.tempMarker === undefined) {
        // offset by infowindow height after recenter
        setTimeout(() => {
          this.map.panBy(0, -100);
        });
      }
    }
  }

  componentDidUpdate() {
    if (this.props.newlyAddedRestaurant !== undefined) {
      this.props.showNewlyAddedInfoWindow();
    }
  }

  render() {
    const setMap = ({ map }) => {
      this.map = map;
    };

    const tempMarkers = [];
    if (this.props.tempMarker !== undefined) {
      tempMarkers.push(<TempMarker key="tempMarker" {...this.props.tempMarker.latLng} />);
    }

    return (
      <section className={s.root} ref={r => { this._root = r; }}>
        <GoogleMap
          defaultZoom={16}
          defaultCenter={this.props.latLng}
          center={this.props.center}
          margin={[100, 0, 0, 0]}
          options={{
            scrollwheel: false
          }}
          onGoogleApiLoaded={setMap}
          onClick={this.props.mapClicked}
          yesIWantToUseGoogleMapApiInternals
        >
          <HereMarker lat={this.props.latLng.lat} lng={this.props.latLng.lng} />
          {tempMarkers}
          {this.props.items.map((item, index) =>
            <RestaurantMarkerContainer
              lat={item.lat}
              lng={item.lng}
              key={`restaurantMarkerContainer_${item.id}`}
              id={item.id}
              index={index}
              baseZIndex={this.props.items.length}
              store={this.context.store}
              insertCss={this.context.insertCss}
            />
          )}
        </GoogleMap>
        <div className={s.mapSettingsContainer}>
          <RestaurantMapSettingsContainer />
        </div>
      </section>
    );
  }
}

export default withStyles(s)(RestaurantMap);
