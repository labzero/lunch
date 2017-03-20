import { connect } from 'react-redux';
import { fetchDecisionIfNeeded, invalidateDecision } from '../../../../actions/decisions';
import { fetchRestaurantsIfNeeded, invalidateRestaurants } from '../../../../actions/restaurants';
import { fetchTagsIfNeeded, invalidateTags } from '../../../../actions/tags';
import Home from './Home';

const mapStateToProps = (state, ownProps) => ({
  teamSlug: ownProps.teamSlug,
  user: state.user
});

const mapDispatchToProps = (dispatch, ownProps) => ({
  fetchRestaurantsIfNeeded() {
    dispatch(fetchRestaurantsIfNeeded(ownProps.teamSlug));
  },
  fetchTagsIfNeeded() {
    dispatch(fetchTagsIfNeeded(ownProps.teamSlug));
  },
  fetchDecisionIfNeeded() {
    dispatch(fetchDecisionIfNeeded(ownProps.teamSlug));
  },
  invalidateDecision() {
    dispatch(invalidateDecision());
  },
  invalidateRestaurants() {
    dispatch(invalidateRestaurants());
  },
  invalidateTags() {
    dispatch(invalidateTags());
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(Home);
