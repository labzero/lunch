import { createNextState } from "@reduxjs/toolkit";
import { Reducer } from "../interfaces";

const mapUi: Reducer<"mapUi"> = (state, action) =>
  createNextState(state, (draftState) => {
    switch (action.type) {
      case "RECEIVE_RESTAURANTS": {
        draftState.infoWindow = {};
        draftState.showPOIs = !action.items.length;
        draftState.showUnvoted = true;
        return;
      }
      case "RESTAURANT_POSTED": {
        draftState.newlyAdded = {
          id: action.restaurant.id,
          userId: action.userId,
        };
        return;
      }
      case "SHOW_GOOGLE_INFO_WINDOW": {
        draftState.center = {
          lat: action.latLng.lat,
          lng: action.latLng.lng,
        };
        draftState.infoWindow = {
          latLng: action.latLng,
          placeId: action.placeId,
        };
        return;
      }
      case "SHOW_RESTAURANT_INFO_WINDOW": {
        draftState.center = {
          lat: action.restaurant.lat,
          lng: action.restaurant.lng,
        };
        draftState.infoWindow = {
          id: action.restaurant.id,
        };
        return;
      }
      case "HIDE_INFO_WINDOW": {
        draftState.infoWindow = {};
        return;
      }
      case "SET_SHOW_POIS": {
        draftState.showPOIs = action.val;

        if (!action.val) {
          draftState.infoWindow = {
            latLng: undefined,
            placeId: undefined,
          };
        }
        return;
      }
      case "SET_SHOW_UNVOTED": {
        draftState.showUnvoted = action.val;
        return;
      }
      case "SET_CENTER": {
        draftState.center = action.center;
        return;
      }
      case "CLEAR_CENTER": {
        draftState.center = undefined;
        return;
      }
      case "CREATE_TEMP_MARKER": {
        draftState.center = action.result.latLng;
        draftState.tempMarker = action.result;
        return;
      }
      case "CLEAR_TEMP_MARKER": {
        draftState.center = undefined;
        draftState.tempMarker = undefined;
        return;
      }
      case "CLEAR_MAP_UI_NEWLY_ADDED": {
        draftState.newlyAdded = undefined;
        break;
      }
      default:
        break;
    }
  });

export default mapUi;
