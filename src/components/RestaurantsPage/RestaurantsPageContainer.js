import { connect } from 'react-redux';
import { fetchRestaurantsIfNeeded, invalidateRestaurants } from '../../actions/restaurants';
import RestaurantsPage from './RestaurantsPage';

const mapStateToProps = state => {
  const { user } = state;
  return { user };
};

const mapDispatchToProps = dispatch => ({
  fetchRestaurantsIfNeeded() {
    dispatch(fetchRestaurantsIfNeeded());
  },
  invalidateRestaurants() {
    dispatch(invalidateRestaurants());
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(RestaurantsPage);
