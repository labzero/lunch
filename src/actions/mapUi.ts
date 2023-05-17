import { ThunkAction } from "@reduxjs/toolkit";
import { Action, LatLng, Restaurant, State } from "../interfaces";
import { getRestaurantById } from "../selectors/restaurants";
import { scrollToTop } from "./pageUi";

export function setCenter(center: LatLng): Action {
  return {
    type: "SET_CENTER",
    center,
  };
}

export function clearCenter(): Action {
  return {
    type: "CLEAR_CENTER",
  };
}

export function showGoogleInfoWindow(
  event: google.maps.IconMouseEvent
): Action {
  return {
    type: "SHOW_GOOGLE_INFO_WINDOW",
    placeId: event.placeId!,
    latLng: {
      lat: event.latLng!.lat(),
      lng: event.latLng!.lng(),
    },
  };
}

export function showRestaurantInfoWindow(restaurant: Restaurant): Action {
  return {
    type: "SHOW_RESTAURANT_INFO_WINDOW",
    restaurant,
  };
}

export function hideInfoWindow(): Action {
  return {
    type: "HIDE_INFO_WINDOW",
  };
}

export function createTempMarker(result: {
  label: string;
  latLng: LatLng;
}): Action {
  return {
    type: "CREATE_TEMP_MARKER",
    result,
  };
}

export function clearTempMarker(): Action {
  return {
    type: "CLEAR_TEMP_MARKER",
  };
}

export function clearNewlyAdded(): Action {
  return {
    type: "CLEAR_MAP_UI_NEWLY_ADDED",
  };
}

export function showMapAndInfoWindow(
  id: number
): ThunkAction<void, State, unknown, Action> {
  return (dispatch, getState) => {
    dispatch(showRestaurantInfoWindow(getRestaurantById(getState(), id)));
    dispatch(scrollToTop());
  };
}

export function setShowUnvoted(val: boolean): Action {
  return {
    type: "SET_SHOW_UNVOTED",
    val,
  };
}

export function setShowPOIs(val: boolean): Action {
  return {
    type: "SET_SHOW_POIS",
    val,
  };
}
