import { connect } from "react-redux";
import { removeDecision } from "../../actions/decisions";
import { showEditNameForm, setEditNameFormValue } from "../../actions/listUi";
import { showMapAndInfoWindow } from "../../actions/mapUi";
import { showModal } from "../../actions/modals";
import { removeRestaurant } from "../../actions/restaurants";
import { Dispatch, State } from "../../interfaces";
import {
  getDecision,
  getDecisionsByRestaurantId,
} from "../../selectors/decisions";
import { getListUiItemForId } from "../../selectors/listUi";
import { getRestaurantById } from "../../selectors/restaurants";
import { getTeamSortDuration } from "../../selectors/team";
import RestaurantDropdown from "./RestaurantDropdown";

interface OwnProps {
  id: number;
}

const mapStateToProps = (state: State, ownProps: OwnProps) => ({
  restaurant: getRestaurantById(state, ownProps.id),
  sortDuration: getTeamSortDuration(state),
  listUiItem: getListUiItemForId(state, ownProps.id),
  decision: getDecision(state),
  pastDecisions: getDecisionsByRestaurantId(state),
  ...ownProps,
});

const mapDispatchToProps = (dispatch: Dispatch, ownProps: OwnProps) => ({
  removeDecision: () => {
    dispatch(removeDecision());
  },
  showPastDecisionsModal: () => {
    dispatch(
      showModal("pastDecisions", {
        restaurantId: ownProps.id,
      })
    );
  },
  showMapAndInfoWindow: () => {
    dispatch(showMapAndInfoWindow(ownProps.id));
  },
  dispatch,
});

const mergeProps = (
  stateProps: ReturnType<typeof mapStateToProps>,
  dispatchProps: ReturnType<typeof mapDispatchToProps>,
  ownProps: OwnProps
) => ({
  ...stateProps,
  ...dispatchProps,
  deleteRestaurant: () =>
    dispatchProps.dispatch(
      showModal("confirm", {
        actionLabel: "Delete",
        body: `Are you sure you want to delete ${stateProps.restaurant.name}?`,
        action: removeRestaurant(ownProps.id),
      })
    ),
  showEditNameForm: () => {
    dispatchProps.dispatch(
      setEditNameFormValue(ownProps.id, stateProps.restaurant.name)
    );
    dispatchProps.dispatch(showEditNameForm(ownProps.id));
  },
});

export default connect(
  mapStateToProps,
  mapDispatchToProps,
  mergeProps
)(RestaurantDropdown);
