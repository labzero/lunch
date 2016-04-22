import React, { Component, PropTypes } from 'react';
import { canUseDOM } from 'fbjs/lib/ExecutionEnvironment';
import RestaurantContainer from '../../containers/RestaurantContainer';

let google;
if (canUseDOM) {
  google = window.google;
} else {
  google = { maps: { Marker: { MAX_ZINDEX: 1000000 } } };
}

export class RestaurantMarker extends Component {
  static propTypes = {
    restaurant: PropTypes.object.isRequired,
    index: PropTypes.number.isRequired,
    baseZIndex: PropTypes.number.isRequired,
    showInfoWindow: PropTypes.bool.isRequired,
    handleMarkerClick: PropTypes.func.isRequired,
    handleMarkerClose: PropTypes.func.isRequired,
    store: PropTypes.object.isRequired,
    insertCss: PropTypes.func.isRequired
  }

  static childContextTypes = {
    insertCss: PropTypes.func.isRequired,
    store: PropTypes.object.isRequired
  }

  getChildContext() {
    return {
      insertCss: this.props.insertCss,
      store: this.props.store
    };
  }

  render() {
    const length = this.props.restaurant.votes.length;
    let label = '';

    let zIndex;

    if (this.props.restaurant.votes.length > 0) {
      if (this.props.restaurant.votes.length > 9) {
        label = '✔';
      } else {
        label = String(length);
      }

      // place markers over default markers
      // place markers higher based on vote length
      // place markers lower based on how far down they are in the list
      // add item length so index doesn't dip below MAX_ZINDEX
      zIndex = google.maps.Marker.MAX_ZINDEX + this.props.restaurant.votes.length - this.props.index + this.props.baseZIndex;
    }

    const ref = `marker_${this.props.index}`;

    const renderInfoWindow = () => (
      <div
        key={`infoWindow_${ref}`}
        onCloseclick={this.props.handleMarkerClose}
      >
        <RestaurantContainer
          id={this.props.restaurant.id}
        />
      </div>
    );

    return (
      <div
        lat={this.props.restaurant.lat}
        lng={this.props.restaurant.lng}
        key={this.props.index}
        title={this.props.restaurant.name}
        onClick={this.props.handleMarkerClick}
        style={{ zIndex }}
      >
        {this.props.showInfoWindow ? renderInfoWindow() : null}
        {label}
      </div>
    );
  }
}
