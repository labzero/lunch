import PropTypes from "prop-types";
import React, { Component } from "react";
import { canUseDOM } from "fbjs/lib/ExecutionEnvironment";
import loadComponent from "../../helpers/loadComponent";
import GoogleMapsLoaderContext from "../GoogleMapsLoaderContext/GoogleMapsLoaderContext";

let Geosuggest = () => null;

class TeamGeosuggest extends Component {
  static contextType = GoogleMapsLoaderContext;

  static propTypes = {
    id: PropTypes.string.isRequired,
    initialValue: PropTypes.string.isRequired,
    onChange: PropTypes.func.isRequired,
    setCenter: PropTypes.func.isRequired,
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
    loadComponent(() =>
      require.ensure(
        [],
        (require) => require("react-geosuggest").default,
        "map"
      )
    ).then((g) => {
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
          const location = results[0].geometry.location;
          const center = {
            lat: location.lat(),
            lng: location.lng(),
          };
          this.props.setCenter(center);
        }
      });
    }
  };

  handleSuggestSelect = (suggestion) => {
    if (suggestion) {
      this.props.setCenter(suggestion.location);
    }
  };

  handleChange = (value) => this.props.onChange({ target: { value } });

  render() {
    const { id, initialValue } = this.props;

    return this.maps ? (
      <Geosuggest
        autoActivateFirstSuggest
        id={id}
        initialValue={initialValue}
        inputClassName="form-control"
        googleMaps={this.maps}
        onActivateSuggest={this.getCoordsForMarker}
        onChange={this.handleChange}
        onSuggestSelect={this.handleSuggestSelect}
        placeholder="Enter team address"
        types={["geocode"]}
      />
    ) : null;
  }
}

export default TeamGeosuggest;
