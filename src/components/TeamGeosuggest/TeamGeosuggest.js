import React, { Component, PropTypes } from 'react';
import { canUseDOM } from 'fbjs/lib/ExecutionEnvironment';
import loadComponent from '../../helpers/loadComponent';

let Geosuggest = () => null;

let google = { maps: { Geocoder: function Geocoder() { return {}; }, GeocoderStatus: {} } };
if (canUseDOM) {
  google = window.google || google;
}

class TeamGeosuggest extends Component {
  static propTypes = {
    id: PropTypes.string.isRequired,
    initialValue: PropTypes.string.isRequired,
    onChange: PropTypes.func.isRequired,
    setCenter: PropTypes.func.isRequired
  };

  constructor(props) {
    super(props);

    this.geocoder = new google.maps.Geocoder();
  }

  componentDidMount() {
    loadComponent(() => require.ensure([], require => require('react-geosuggest').default, 'map')).then((g) => {
      Geosuggest = g;
      this.forceUpdate();
    });
  }

  getCoordsForMarker = (suggest) => {
    if (suggest !== null) {
      this.geocoder.geocode({ placeId: suggest.placeId }, (results, status) => {
        if (status === google.maps.GeocoderStatus.OK) {
          const location = results[0].geometry.location;
          const center = {
            lat: location.lat(),
            lng: location.lng()
          };
          this.props.setCenter(center);
        }
      });
    }
  }

  handleSuggestSelect = (suggestion) => {
    this.props.setCenter(suggestion.location);
  }

  handleChange = value => this.props.onChange({ target: { value } });

  render() {
    const { id, initialValue } = this.props;

    return (
      <Geosuggest
        autoActivateFirstSuggest
        id={id}
        initialValue={initialValue}
        inputClassName="form-control"
        onActivateSuggest={this.getCoordsForMarker}
        onChange={this.handleChange}
        onSuggestSelect={this.handleSuggestSelect}
        placeholder="Enter team address"
        types={['geocode']}
      />
    );
  }
}

export default TeamGeosuggest;
