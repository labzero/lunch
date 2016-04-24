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

class RestaurantMap extends Component {
  static contextTypes = {
    insertCss: PropTypes.func.isRequired,
    store: PropTypes.object.isRequired
  };

  static propTypes = {
    items: PropTypes.array.isRequired,
    latLng: PropTypes.object.isRequired,
    center: PropTypes.object,
    clearCenter: PropTypes.func.isRequired,
    mapClicked: PropTypes.func.isRequired,
  };

  componentWillReceiveProps(nextProps) {
    if (nextProps.center !== undefined) {
      this.props.clearCenter();
      // offset by infowindow height after recenter
      setTimeout(() => {
        this.map.panBy(0, -100);
      });
    }
  }

  render() {
    const setMap = ({ map }) => {
      this.map = map;
    };

    return (
      <section className={s.root}>
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
          <div
            lat={this.props.latLng.lat}
            lng={this.props.latLng.lng}
            className={s.center}
            title="You are here"
          />
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

export default withStyles(RestaurantMap, s);
