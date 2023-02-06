import PropTypes from 'prop-types';
import React, { Component } from 'react';
import { canUseDOM } from 'fbjs/lib/ExecutionEnvironment';
import withStyles from 'isomorphic-style-loader/withStyles';
import loadComponent from '../../helpers/loadComponent';
import s from './RestaurantAddForm.scss';
import generateMessageDescriptor from '../../helpers/generateMessageDescriptor';

const m = generateMessageDescriptor('RestaurantAddForm');

let google = {
  maps: {
    Geocoder: function Geocoder() {
      return {};
    },
    GeocoderStatus: {},
  },
};
if (canUseDOM) {
  google = window.google || google;
}

const renderNull = () => null;
let Geosuggest = renderNull;

class RestaurantAddForm extends Component {
  static propTypes = {
    getSuggestLabel: PropTypes.func.isRequired,
    createTempMarker: PropTypes.func.isRequired,
    clearTempMarker: PropTypes.func.isRequired,
    handleSuggestSelect: PropTypes.func.isRequired,
    latLng: PropTypes.object.isRequired,
    intl: PropTypes.shape().isRequired,
  };

  constructor(props) {
    super(props);
    this.geocoder = new google.maps.Geocoder();
  }

  componentDidMount() {
    loadComponent(() => require.ensure(
      [],
      (require) => require('react-geosuggest').default,
      'map'
    )).then((g) => {
      Geosuggest = g;
      this.forceUpdate();
    });
  }

  getCoordsForMarker = (suggest) => {
    if (suggest !== null) {
      this.geocoder.geocode({ placeId: suggest.placeId }, (results, status) => {
        if (status === google.maps.GeocoderStatus.OK) {
          this.props.createTempMarker(results[0]);
        }
      });
    }
  };

  handleSuggestSelect = (suggestion) => {
    this.props.handleSuggestSelect(suggestion, this.geosuggest);
  };

  render() {
    const {
      intl: { formatMessage: f },
    } = this.props;

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
          location={{
            lat: () => this.props.latLng.lat,
            lng: () => this.props.latLng.lng,
          }}
          placeholder={f(m('addPlaces'))}
          radius="0"
          onBlur={this.props.clearTempMarker}
          onActivateSuggest={this.getCoordsForMarker}
          onSuggestSelect={this.handleSuggestSelect}
          getSuggestLabel={this.props.getSuggestLabel}
          // to silence ref warning in React 16
          ref={
            Geosuggest === renderNull
              ? undefined
              : (g) => {
                this.geosuggest = g;
              }
          }
        />
      </form>
    );
  }
}

export default withStyles(s)(RestaurantAddForm);
