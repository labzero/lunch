import { connect } from 'react-redux';
import { fetchDecisionIfNeeded, invalidateDecision } from '../../../actions/decisions';
import { fetchRestaurantsIfNeeded, invalidateRestaurants } from '../../../actions/restaurants';
import { fetchTagsIfNeeded, invalidateTags } from '../../../actions/tags';
import { fetchUsersIfNeeded, invalidateUsers } from '../../../actions/users';
import { messageReceived } from '../../../actions/websockets';
import Home from './Home';

const mapStateToProps = state => ({
  user: state.user,
  wsPort: state.wsPort
});

const mapDispatchToProps = dispatch => ({
  fetchDecisionIfNeeded() {
    dispatch(fetchDecisionIfNeeded());
  },
  fetchRestaurantsIfNeeded() {
    dispatch(fetchRestaurantsIfNeeded());
  },
  fetchTagsIfNeeded() {
    dispatch(fetchTagsIfNeeded());
  },
  fetchUsersIfNeeded() {
    dispatch(fetchUsersIfNeeded());
  },
  invalidateDecision() {
    dispatch(invalidateDecision());
  },
  invalidateRestaurants() {
    dispatch(invalidateRestaurants());
  },
  invalidateTags() {
    dispatch(invalidateTags());
  },
  invalidateUsers() {
    dispatch(invalidateUsers());
  },
  messageReceived(event) {
    dispatch(messageReceived(event.data));
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(Home);
