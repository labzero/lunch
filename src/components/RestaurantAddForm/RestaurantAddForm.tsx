/* eslint-disable max-classes-per-file */

import React, { Component, RefObject, Suspense, createRef, lazy } from "react";
import GeosuggestClass, { GeosuggestProps, Suggest } from "react-geosuggest";
import withStyles from "isomorphic-style-loader/withStyles";
import canUseDOM from "../../helpers/canUseDOM";
import { LatLng } from "../../interfaces";
import GoogleMapsLoaderContext, {
  IGoogleMapsLoaderContext,
} from "../GoogleMapsLoaderContext/GoogleMapsLoaderContext";
import s from "./RestaurantAddForm.scss";

const Geosuggest = lazy(
  () => import(/* webpackChunkName: 'geosuggest' */ "react-geosuggest")
);

interface RestaurantAddFormProps
  extends Pick<GeosuggestProps, "getSuggestLabel"> {
  createTempMarker: (result: google.maps.GeocoderResult) => void;
  clearTempMarker: () => void;
  handleSuggestSelect: (
    suggestion: Suggest,
    geosuggest: GeosuggestClass
  ) => void;
  latLng: LatLng;
}

class RestaurantAddForm extends Component<RestaurantAddFormProps> {
  static contextType = GoogleMapsLoaderContext;

  geocoder: google.maps.Geocoder;

  geosuggest: RefObject<GeosuggestClass>;

  maps: typeof google.maps;

  constructor(
    props: RestaurantAddFormProps,
    context: IGoogleMapsLoaderContext
  ) {
    super(props, context);

    this.geosuggest = createRef();

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
          this.props.createTempMarker(results![0]);
        }
      });
    }
  };

  handleSuggestSelect = (suggestion: Suggest) => {
    this.props.handleSuggestSelect(suggestion, this.geosuggest!.current!);
    this.geosuggest.current?.clear();
    this.geosuggest.current?.focus();
  };

  render() {
    return (
      <form>
        {this.maps ? (
          <Suspense fallback={null}>
            <Geosuggest
              autoActivateFirstSuggest
              bounds={
                new google.maps.LatLngBounds(
                  new google.maps.LatLng(
                    this.props.latLng.lat,
                    this.props.latLng.lng
                  )
                )
              }
              className={s.geosuggest}
              ignoreTab
              inputClassName={s.input}
              googleMaps={this.maps}
              suggestItemClassName={s.suggestItem}
              suggestItemActiveClassName={s.suggestItemActive}
              suggestsClassName={s.suggests}
              placeholder="Add places"
              onBlur={this.props.clearTempMarker}
              onActivateSuggest={this.getCoordsForMarker}
              onSuggestSelect={this.handleSuggestSelect}
              getSuggestLabel={this.props.getSuggestLabel}
              ref={this.geosuggest}
            />
          </Suspense>
        ) : null}
      </form>
    );
  }
}

export default withStyles(s)(RestaurantAddForm);
