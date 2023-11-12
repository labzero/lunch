import { Location, Suggest } from "@ubilabs/react-geosuggest";
import { connect } from "react-redux";
import { scroller } from "react-scroll";
import { Dispatch, State } from "../../interfaces";
import { getRestaurants } from "../../selectors/restaurants";
import { getTeamLatLng } from "../../selectors/team";
import { addRestaurant } from "../../actions/restaurants";
import { createTempMarker, clearTempMarker } from "../../actions/mapUi";
import RestaurantAddForm from "./RestaurantAddForm";

// Keep a cache of terms[0] since our geosuggest library doesn't allow us to receive a label
// different than what is in the suggest dropdown
let suggestCache: { [placeId: string]: string } = {};

const mapStateToProps = (state: State) => ({
  latLng: getTeamLatLng(state),
  restaurants: getRestaurants(state),
});

const mapDispatchToProps = (dispatch: Dispatch) => ({
  getSuggestLabel: (suggest: Suggest) => {
    if (suggest.terms !== undefined && suggest.terms.length > 0) {
      suggestCache[suggest.place_id] = suggest.terms[0].value;
    }
    return suggest.description;
  },
  createTempMarker: (result: google.maps.GeocoderResult) => {
    const location = result.geometry.location;
    const marker = {
      label: suggestCache[result.place_id],
      latLng: {
        lat: location.lat(),
        lng: location.lng(),
      },
    };
    dispatch(createTempMarker(marker));
  },
  clearTempMarker: () => {
    dispatch(clearTempMarker());
  },
  dispatch,
});

const mergeProps = (
  stateProps: ReturnType<typeof mapStateToProps>,
  dispatchProps: ReturnType<typeof mapDispatchToProps>
) => ({
  ...stateProps,
  ...dispatchProps,
  handleSuggestSelect: (suggestion: Location | undefined) => {
    if (suggestion) {
      let name = suggestion.label;
      let address = "";
      const {
        placeId,
        location: { lat, lng },
      } = suggestion;
      const isEstablishment =
        suggestion.gmaps &&
        suggestion.gmaps.types &&
        suggestion.gmaps.types.indexOf("establishment") > -1;
      if (suggestCache[placeId] !== undefined && isEstablishment) {
        name = suggestCache[placeId];
      } else if (!isEstablishment) {
        name = name.split(",")[0];
      }
      if (suggestion.gmaps !== undefined) {
        address = suggestion.gmaps.formatted_address || "";
      }
      suggestCache = {};
      const existingRestaurant = stateProps.restaurants.find(
        (r) => r.placeId === placeId
      );
      if (existingRestaurant === undefined) {
        dispatchProps.dispatch(addRestaurant(name, placeId, address, lat, lng));
      } else {
        scroller.scrollTo(`restaurantListItem_${existingRestaurant.id}`, {
          containerId: "listContainer",
          offset: document.getElementById("listForms")!.offsetHeight,
          smooth: true,
        });
        scroller.scrollTo(`restaurantListItem_${existingRestaurant.id}`, {});
      }
    }
    dispatchProps.dispatch(clearTempMarker());
  },
});

export default connect(
  mapStateToProps,
  mapDispatchToProps,
  mergeProps
)(RestaurantAddForm);
