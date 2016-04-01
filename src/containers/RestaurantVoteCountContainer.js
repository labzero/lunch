import { connect } from 'react-redux';
import RestaurantVoteCount from '../components/RestaurantVoteCount';

const mapStateToProps = (state, ownProps) => ({
  user: state.user,
  users: state.users.items,
  ...ownProps
});

export default connect(
  mapStateToProps
)(RestaurantVoteCount);
