import React, { Component, PropTypes } from 'react';
import { canUseDOM } from 'fbjs/lib/ExecutionEnvironment';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import Geosuggest from 'react-geosuggest';
import s from './RestaurantAddForm.scss';

let google = { maps: { Geocoder: function Geocoder() { return {}; }, GeocoderStatus: {} } };
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

  constructor(props) {
    super(props);
    this.geocoder = new google.maps.Geocoder();
  }

  getCoordsForMarker = (suggest) => {
    if (suggest !== null) {
      this.geocoder.geocode({ placeId: suggest.placeId }, (results, status) => {
        if (status === google.maps.GeocoderStatus.OK) {
          this.props.createTempMarker(results[0]);
        }
      });
    }
  }

  handleSuggestSelect = (suggestion) => {
    this.props.handleSuggestSelect(suggestion, this.geosuggest);
  }

  render() {
    return (
      <form>
        <Geosuggest
          autoActivateFirstSuggest
          className={s.geosuggest}
          ignoreTab
          inputClassName={s.input}
          suggestItemClassName={s.suggestItem}
          suggestItemActiveClassName={s.suggestItemActive}
          suggestsClassName={s.suggests}
          location={{ lat: () => this.props.latLng.lat, lng: () => this.props.latLng.lng }}
          radius="0"
          onBlur={this.props.clearTempMarker}
          onActivateSuggest={this.getCoordsForMarker}
          onSuggestSelect={this.handleSuggestSelect}
          getSuggestLabel={this.props.getSuggestLabel}
          ref={g => { this.geosuggest = g; }}
          types={['establishment']}
        />
      </form>
    );
  }

}

export default withStyles(s)(RestaurantAddForm);
