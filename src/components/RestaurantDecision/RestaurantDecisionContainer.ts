import { connect } from "react-redux";
import { decide, removeDecision } from "../../actions/decisions";
import { Dispatch, State } from "../../interfaces";
import { getDecision } from "../../selectors/decisions";
import { getRestaurantById } from "../../selectors/restaurants";
import RestaurantDecision from "./RestaurantDecision";

interface OwnProps {
  id: number;
}

const mapStateToProps = (state: State, ownProps: OwnProps) => {
  const decision = getDecision(state);
  return {
    id: ownProps.id,
    loggedIn: state.user !== null,
    decided: decision !== undefined && decision.restaurantId === ownProps.id,
    votes: getRestaurantById(state, ownProps.id).votes,
  };
};

const mapDispatchToProps = (dispatch: Dispatch) => ({
  dispatch,
});

const mergeProps = (
  stateProps: ReturnType<typeof mapStateToProps>,
  dispatchProps: ReturnType<typeof mapDispatchToProps>,
  ownProps: OwnProps
) => ({
  ...stateProps,
  ...dispatchProps,
  handleClick() {
    if (stateProps.loggedIn) {
      if (stateProps.decided) {
        dispatchProps.dispatch(removeDecision());
      } else {
        dispatchProps.dispatch(decide(ownProps.id));
      }
    }
  },
});

export default connect(
  mapStateToProps,
  mapDispatchToProps,
  mergeProps
)(RestaurantDecision);
