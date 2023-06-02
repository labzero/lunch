import { connect } from "react-redux";
import { ThunkDispatch } from "redux-thunk";
import { removeVote, addVote } from "../../actions/restaurants";
import { Action, State } from "../../interfaces";
import { makeGetRestaurantVotesForUser } from "../../selectors";
import RestaurantVoteButton from "./RestaurantVoteButton";

interface OwnProps {
  id: number;
}

const mapStateToProps = () => {
  const getRestaurantVotesForUser = makeGetRestaurantVotesForUser();
  return (state: State, ownProps: OwnProps) => {
    const props = { restaurantId: ownProps.id, userId: state.user?.id };
    return {
      userVotes: getRestaurantVotesForUser(state, props),
    };
  };
};

const mapDispatchToProps = null;

const mergeProps = (
  stateProps: ReturnType<ReturnType<typeof mapStateToProps>>,
  dispatchProps: { dispatch: ThunkDispatch<State, void, Action> },
  ownProps: OwnProps
) => ({
  ...stateProps,
  ...dispatchProps,
  handleClick: () => {
    if (stateProps.userVotes.length > 0) {
      stateProps.userVotes.forEach((vote) => {
        dispatchProps.dispatch(removeVote(ownProps.id, vote));
      });
    } else {
      dispatchProps.dispatch(addVote(ownProps.id));
    }
  },
});

export default connect(
  mapStateToProps,
  mapDispatchToProps,
  mergeProps
)(RestaurantVoteButton);
