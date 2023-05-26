import { MouseEvent } from "react";
import { connect } from "react-redux";
import { Dispatch, State } from "../../interfaces";
import { getRestaurantById } from "../../selectors/restaurants";
import { getDecision } from "../../selectors/decisions";
import { showRestaurantInfoWindow, hideInfoWindow } from "../../actions/mapUi";
import { getMapUi } from "../../selectors/mapUi";
import RestaurantMarker from "./RestaurantMarker";

const mapStateToProps = (state: State, ownProps: { id: number }) => {
  const restaurant = getRestaurantById(state, ownProps.id);
  const decision = getDecision(state);
  const decided =
    decision !== undefined && decision.restaurantId === restaurant.id;
  const mapUi = getMapUi(state);
  return {
    restaurant,
    decided,
    showInfoWindow:
      "id" in mapUi.infoWindow && mapUi.infoWindow.id === ownProps.id,
    ...ownProps,
  };
};

const mapDispatchToProps = (dispatch: Dispatch) => ({
  dispatch,
});

const mergeProps = (
  stateProps: ReturnType<typeof mapStateToProps>,
  dispatchProps: ReturnType<typeof mapDispatchToProps>
) => ({
  ...stateProps,
  ...dispatchProps,
  handleMarkerClick(event: MouseEvent) {
    event.preventDefault();
    // prevents POIs from receiving click event afterwards
    event.stopPropagation();
    if (stateProps.showInfoWindow) {
      dispatchProps.dispatch(hideInfoWindow());
    } else {
      dispatchProps.dispatch(showRestaurantInfoWindow(stateProps.restaurant));
    }
  },
});

export default connect(
  mapStateToProps,
  mapDispatchToProps,
  mergeProps
)(RestaurantMarker);
