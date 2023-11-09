import React, { Component, Suspense, lazy } from "react";
import { Suggest } from "@ubilabs/react-geosuggest";
import canUseDOM from "../../helpers/canUseDOM";
import { LatLng } from "../../interfaces";
import GoogleMapsLoaderContext, {
  IGoogleMapsLoaderContext,
} from "../GoogleMapsLoaderContext/GoogleMapsLoaderContext";

const Geosuggest = lazy(
  () => import(/* webpackChunkName: 'geosuggest' */ "@ubilabs/react-geosuggest")
);

export interface TeamGeosuggestProps {
  id: string;
  initialValue?: string;
  onChange: (value: string) => void;
  setCenter: (center: LatLng) => void;
}

class TeamGeosuggest extends Component<TeamGeosuggestProps> {
  static contextType = GoogleMapsLoaderContext;

  static defaultProps = {
    initialValue: undefined,
  };

  geocoder: google.maps.Geocoder;

  maps: typeof google.maps;

  constructor(props: TeamGeosuggestProps, context: IGoogleMapsLoaderContext) {
    super(props, context);

    if (canUseDOM) {
      const { loader } = context;
      loader?.load().then((google) => {
        this.maps = google.maps;
        this.forceUpdate();
      });
    }
  }

  getCoordsForMarker = (suggest: Suggest) => {
    if (suggest !== null) {
      if (this.geocoder === undefined) {
        this.geocoder = new this.maps.Geocoder();
      }
      this.geocoder.geocode({ placeId: suggest.placeId }, (results, status) => {
        if (status === this.maps.GeocoderStatus.OK) {
          const location = results![0].geometry.location;
          const center = {
            lat: location.lat(),
            lng: location.lng(),
          };
          this.props.setCenter(center);
        }
      });
    }
  };

  handleSuggestSelect = (suggestion: Suggest) => {
    if (suggestion) {
      this.props.setCenter(suggestion.location);
    }
  };

  render() {
    const { id, initialValue } = this.props;

    return this.maps ? (
      <Suspense fallback={null}>
        <Geosuggest
          autoActivateFirstSuggest
          id={id}
          initialValue={initialValue}
          inputClassName="form-control"
          googleMaps={this.maps}
          onActivateSuggest={this.getCoordsForMarker}
          onChange={this.props.onChange}
          onSuggestSelect={this.handleSuggestSelect}
          placeholder="Enter team address"
          types={["geocode"]}
        />
      </Suspense>
    ) : null;
  }
}

export default TeamGeosuggest;
