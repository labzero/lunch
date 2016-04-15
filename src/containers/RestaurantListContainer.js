import { connect } from 'react-redux';
import { getFilteredRestaurants } from '../selectors';
import RestaurantList from '../components/RestaurantList';

const mapStateToProps = state => ({
  ids: getFilteredRestaurants(state)
});

export default connect(mapStateToProps)(RestaurantList);
