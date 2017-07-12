import { connect } from 'react-redux';
import { getFilteredRestaurants, isRestaurantListReady } from '../../selectors';
import { getFlipMove } from '../../selectors/listUi';
import { getRestaurantIds } from '../../selectors/restaurants';
import RestaurantList from './RestaurantList';

const mapStateToProps = state => ({
  allRestaurantIds: getRestaurantIds(state),
  flipMove: getFlipMove(state),
  ids: getFilteredRestaurants(state),
  restaurantListReady: isRestaurantListReady(state)
});

export default connect(mapStateToProps)(RestaurantList);
