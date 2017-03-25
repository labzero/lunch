import { connect } from 'react-redux';
import { fetchDecisionIfNeeded, invalidateDecision } from '../../../../actions/decisions';
import { fetchRestaurantsIfNeeded, invalidateRestaurants } from '../../../../actions/restaurants';
import { fetchTagsIfNeeded, invalidateTags } from '../../../../actions/tags';
import { fetchUsersIfNeeded, invalidateUsers } from '../../../../actions/users';
import { messageReceived } from '../../../../actions/websockets';
import Home from './Home';

const mapStateToProps = (state, ownProps) => ({
  teamSlug: ownProps.teamSlug,
  user: state.user,
  wsPort: state.wsPort
});

const mapDispatchToProps = (dispatch, ownProps) => ({
  fetchDecisionIfNeeded() {
    dispatch(fetchDecisionIfNeeded(ownProps.teamSlug));
  },
  fetchRestaurantsIfNeeded() {
    dispatch(fetchRestaurantsIfNeeded(ownProps.teamSlug));
  },
  fetchTagsIfNeeded() {
    dispatch(fetchTagsIfNeeded(ownProps.teamSlug));
  },
  fetchUsersIfNeeded() {
    dispatch(fetchUsersIfNeeded(ownProps.teamSlug));
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
