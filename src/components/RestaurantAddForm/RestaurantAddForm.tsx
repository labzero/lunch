/* eslint-disable max-classes-per-file */

import React, { Component } from "react";
import { Loader } from "@googlemaps/js-api-loader";
import GeosuggestClass, { GeosuggestProps, Suggest } from "react-geosuggest";
import { IntlShape } from "react-intl";
import { canUseDOM } from "fbjs/lib/ExecutionEnvironment";
import withStyles from "isomorphic-style-loader/withStyles";
import loadComponent from "../../helpers/loadComponent";
import generateMessageDescriptor from "../../helpers/generateMessageDescriptor";
import { LatLng } from "../../interfaces";
import GoogleMapsLoaderContext from "../GoogleMapsLoaderContext/GoogleMapsLoaderContext";
import s from "./RestaurantAddForm.scss";

const m = generateMessageDescriptor("RestaurantAddForm");

class RenderNull extends GeosuggestClass {
  render() {
    return null;
  }
}

let Geosuggest: typeof GeosuggestClass = RenderNull;

interface RestaurantAddFormProps
  extends Pick<GeosuggestProps, "getSuggestLabel"> {
  createTempMarker: (result: google.maps.GeocoderResult) => void;
  clearTempMarker: () => void;
  handleSuggestSelect: (
    suggestion: Suggest,
    geosuggest: GeosuggestClass
  ) => void;
  latLng: LatLng;
  intl: IntlShape;
}

interface RestaurantAddFormContext {
  loader: Loader;
}

class RestaurantAddForm extends Component<RestaurantAddFormProps> {
  static contextType = GoogleMapsLoaderContext;

  geocoder: google.maps.Geocoder;

  geosuggest: GeosuggestClass;

  maps: typeof google.maps;

  constructor(
    props: RestaurantAddFormProps,
    context: RestaurantAddFormContext
  ) {
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
            placeholder={f(m("addPlaces"))}
            onBlur={this.props.clearTempMarker}
            onActivateSuggest={this.getCoordsForMarker}
            onSuggestSelect={this.handleSuggestSelect}
            getSuggestLabel={this.props.getSuggestLabel}
            // to silence ref warning in React 16
            ref={
              Geosuggest === RenderNull
                ? undefined
                : (g: GeosuggestClass) => {
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
