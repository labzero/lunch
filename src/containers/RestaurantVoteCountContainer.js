import { connect } from 'react-redux';
import { getRestaurantById } from '../selectors/restaurants';
import RestaurantVoteCount from '../components/RestaurantVoteCount';

const mapStateToProps = (state, ownProps) => ({
  user: state.user,
  votes: getRestaurantById(state, ownProps.id).votes,
  ...ownProps
});

export default connect(
  mapStateToProps
)(RestaurantVoteCount);
