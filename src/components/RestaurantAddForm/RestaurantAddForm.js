import React, { Component, PropTypes } from 'react';
import { canUseDOM } from 'fbjs/lib/ExecutionEnvironment';
import Geosuggest from 'react-geosuggest';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './RestaurantAddForm.scss';

let google = { maps: { Geocoder: () => ({}), GeocoderStatus: {} } };
if (canUseDOM) {
  google = window.google || google;
}

class RestaurantAddForm extends Component {

  static propTypes = {
    getSuggestLabel: PropTypes.func.isRequired,
    createTempMarker: PropTypes.func.isRequired,
    clearTempMarker: PropTypes.func.isRequired,
    handleSuggestSelect: PropTypes.func.isRequired,
    latLng: PropTypes.object.isRequired
  };

  static contextTypes = {
    insertCss: PropTypes.func,
  };

  constructor(props) {
    super(props);
    this.geocoder = new google.maps.Geocoder();
  }

  componentWillMount() {
    this.removeCss = this.context.insertCss(s);
  }

  componentWillUnmount() {
    this.removeCss();
  }

  getCoordsForMarker(suggest) {
    if (suggest !== null) {
      this.geocoder.geocode({ placeId: suggest.placeId }, (results, status) => {
        if (status === google.maps.GeocoderStatus.OK) {
          this.props.createTempMarker(results[0]);
        }
      });
    }
  }

  handleSuggestSelect(suggestion) {
    this.props.handleSuggestSelect(suggestion, this._geosuggest);
  }

  render() {
    const boundHandleSuggestSelect = this.handleSuggestSelect.bind(this);
    const boundGetCoordsForMarker = this.getCoordsForMarker.bind(this);

    return (
      <form>
        <Geosuggest
          autoActivateFirstSuggest
          location={{ lat: () => this.props.latLng.lat, lng: () => this.props.latLng.lng }}
          radius="0"
          onBlur={this.props.clearTempMarker}
          onActivateSuggest={boundGetCoordsForMarker}
          onSuggestSelect={boundHandleSuggestSelect}
          getSuggestLabel={this.props.getSuggestLabel}
          ref={g => { this._geosuggest = g; }}
          types={[
            'establishment'
          ]}
        />
      </form>
    );
  }

}

export default withStyles(s)(RestaurantAddForm);
