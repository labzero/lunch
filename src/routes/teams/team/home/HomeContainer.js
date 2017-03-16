import { connect } from 'react-redux';
import { fetchRestaurantsIfNeeded, invalidateRestaurants } from '../../../../actions/restaurants';
import Home from './Home';

const mapStateToProps = (state, ownProps) => ({
  teamSlug: ownProps.teamSlug,
  user: state.user
});

const mapDispatchToProps = (dispatch, ownProps) => ({
  fetchRestaurantsIfNeeded() {
    dispatch(fetchRestaurantsIfNeeded(ownProps.teamSlug));
  },
  invalidateRestaurants() {
    dispatch(invalidateRestaurants());
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(Home);
