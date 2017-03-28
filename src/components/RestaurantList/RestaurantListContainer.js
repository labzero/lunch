import { connect } from 'react-redux';
import { getFilteredRestaurants, isRestaurantListReady } from '../../selectors';
import RestaurantList from './RestaurantList';

const mapStateToProps = state => ({
  ids: getFilteredRestaurants(state),
  restaurantListReady: isRestaurantListReady(state)
});

export default connect(mapStateToProps)(RestaurantList);
