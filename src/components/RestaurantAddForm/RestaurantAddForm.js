import PropTypes from 'prop-types';
import React, { Component } from 'react';
import { canUseDOM } from 'fbjs/lib/ExecutionEnvironment';
import withStyles from 'isomorphic-style-loader/withStyles';
import loadComponent from '../../helpers/loadComponent';
import s from './RestaurantAddForm.scss';
import generateMessageDescriptor from '../../helpers/generateMessageDescriptor';
import GoogleMapsLoaderContext from '../GoogleMapsLoaderContext/GoogleMapsLoaderContext';

const m = generateMessageDescriptor('RestaurantAddForm');

const renderNull = () => null;
let Geosuggest = renderNull;

class RestaurantAddForm extends Component {
  static contextType = GoogleMapsLoaderContext;

  static propTypes = {
    getSuggestLabel: PropTypes.func.isRequired,
    createTempMarker: PropTypes.func.isRequired,
    clearTempMarker: PropTypes.func.isRequired,
    handleSuggestSelect: PropTypes.func.isRequired,
    latLng: PropTypes.object.isRequired,
    intl: PropTypes.shape().isRequired,
  };

  constructor(props, context) {
    super(props, context);

    if (canUseDOM) {
      const { loader } = context;
      loader.load().then((google) => {
        this.maps = google.maps;
        this.forceUpdate();
      });
    }
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
      if (this.geocoder === undefined) {
        this.geocoder = new this.maps.Geocoder();
      }
      this.geocoder.geocode({ placeId: suggest.placeId }, (results, status) => {
        if (status === this.maps.GeocoderStatus.OK) {
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
        {this.maps ? (
          <Geosuggest
            autoActivateFirstSuggest
            className={s.geosuggest}
            ignoreTab
            inputClassName={s.input}
            googleMaps={this.maps}
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
        ) : null}
      </form>
    );
  }
}

export default withStyles(s)(RestaurantAddForm);
