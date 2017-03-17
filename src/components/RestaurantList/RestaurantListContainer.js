import { connect } from 'react-redux';
import { getFilteredRestaurants, isRestaurantListReady } from '../../selectors';
import RestaurantList from './RestaurantList';

const mapStateToProps = (state, ownProps) => ({
  ids: getFilteredRestaurants(state),
  restaurantListReady: isRestaurantListReady(state),
  teamSlug: ownProps.teamSlug
});

export default connect(mapStateToProps)(RestaurantList);
