import { connect } from "react-redux";
import { State } from "../../interfaces";
import { getRestaurantById } from "../../selectors/restaurants";
import RestaurantVoteCount from "./RestaurantVoteCount";

interface OwnProps {
  id: number;
}

const mapStateToProps = (state: State, ownProps: OwnProps) => ({
  user: state.user,
  votes: getRestaurantById(state, ownProps.id).votes,
  ...ownProps,
});

export default connect(mapStateToProps)(RestaurantVoteCount);
