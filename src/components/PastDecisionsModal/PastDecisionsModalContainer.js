import { connect } from "react-redux";
import { decide } from "../../actions/decisions";
import { hideModal } from "../../actions/modals";
import { getDecisionsByDay } from "../../selectors/decisions";
import { getRestaurantEntities } from "../../selectors/restaurants";
import PastDecisionsModal from "./PastDecisionsModal";

const modalName = "pastDecisions";

const mapStateToProps = (state) => ({
  decisionsByDay: getDecisionsByDay(state),
  restaurantId: state.modals[modalName].restaurantId,
  restaurantEntities: getRestaurantEntities(state),
  shown: !!state.modals[modalName].shown,
});

const mapDispatchToProps = (dispatch) => ({
  dispatch,
  hideModal: () => dispatch(hideModal(modalName)),
});

const mergeProps = (stateProps, dispatchProps) => ({
  ...stateProps,
  ...dispatchProps,
  decide: (daysAgo) =>
    dispatchProps
      .dispatch(decide(stateProps.restaurantId, daysAgo))
      .then(dispatchProps.hideModal),
});

export default connect(
  mapStateToProps,
  mapDispatchToProps,
  mergeProps
)(PastDecisionsModal);
