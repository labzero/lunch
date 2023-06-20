import { connect } from "react-redux";
import { decide } from "../../actions/decisions";
import { hideModal } from "../../actions/modals";
import {
  Dispatch,
  State,
  PastDecisionsModal as PastDecisionsModalType,
} from "../../interfaces";
import { getDecisionsByDay } from "../../selectors/decisions";
import { getRestaurantEntities } from "../../selectors/restaurants";
import PastDecisionsModal from "./PastDecisionsModal";

const modalName = "pastDecisions";

const mapStateToProps = (state: State) => ({
  decisionsByDay: getDecisionsByDay(state),
  restaurantId: (state.modals[modalName] as PastDecisionsModalType)
    .restaurantId,
  restaurantEntities: getRestaurantEntities(state),
  shown: !!state.modals[modalName].shown,
});

const mapDispatchToProps = (dispatch: Dispatch) => ({
  dispatch,
  hideModal: () => dispatch(hideModal(modalName)),
});

const mergeProps = (
  stateProps: ReturnType<typeof mapStateToProps>,
  dispatchProps: ReturnType<typeof mapDispatchToProps>
) => ({
  ...stateProps,
  ...dispatchProps,
  decide: (daysAgo: number) =>
    dispatchProps
      .dispatch(decide(stateProps.restaurantId!, daysAgo))
      .then(dispatchProps.hideModal),
});

export default connect(
  mapStateToProps,
  mapDispatchToProps,
  mergeProps
)(PastDecisionsModal);
