import { connect } from "react-redux";
import { ClickEventValue } from "google-map-react";
import {
  clearCenter,
  clearNewlyAdded,
  hideInfoWindow,
  showGoogleInfoWindow,
  showRestaurantInfoWindow,
} from "../../actions/mapUi";
import { Dispatch, State } from "../../interfaces";
import { getRestaurantById } from "../../selectors/restaurants";
import { getTeamDefaultZoom, getTeamLatLng } from "../../selectors/team";
import { getMapUi } from "../../selectors/mapUi";
import { getCurrentUser } from "../../selectors/user";
import { getMapItems } from "../../selectors";
import RestaurantMap from "./RestaurantMap";

const mapStateToProps = (state: State) => {
  const mapUi = getMapUi(state);
  return {
    infoWindow: mapUi.infoWindow,
    items: getMapItems(state),
    center: mapUi.center,
    defaultZoom: getTeamDefaultZoom(state),
    tempMarker: mapUi.tempMarker,
    newlyAddedRestaurant: mapUi.newlyAdded
      ? getRestaurantById(state, mapUi.newlyAdded.id)
      : undefined,
    newlyAddedUserId: mapUi.newlyAdded ? mapUi.newlyAdded.userId : undefined,
    latLng: getTeamLatLng(state),
    showPOIs: mapUi.showPOIs,
    user: getCurrentUser(state),
  };
};

const mapDispatchToProps = (dispatch: Dispatch) => ({
  clearCenter: () => dispatch(clearCenter()),
  mapClicked: ({ event }: ClickEventValue) => {
    if (!event.target.closest("[data-marker]")) {
      dispatch(hideInfoWindow());
    }
  },
  showGoogleInfoWindow: (event: google.maps.IconMouseEvent) =>
    dispatch(showGoogleInfoWindow(event)),
  dispatch,
});

const mergeProps = (
  stateProps: ReturnType<typeof mapStateToProps>,
  dispatchProps: ReturnType<typeof mapDispatchToProps>
) => ({
  ...stateProps,
  ...dispatchProps,
  showNewlyAddedInfoWindow: () => {
    if (stateProps.newlyAddedUserId === stateProps.user?.id) {
      dispatchProps.dispatch(
        showRestaurantInfoWindow(stateProps.newlyAddedRestaurant!)
      );
      dispatchProps.dispatch(clearNewlyAdded());
    }
  },
});

export default connect(
  mapStateToProps,
  mapDispatchToProps,
  mergeProps
)(RestaurantMap);
