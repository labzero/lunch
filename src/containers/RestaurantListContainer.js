import { connect } from 'react-redux';
import RestaurantList from '../components/RestaurantList';

const mapStateToProps = state => {
  let items = state.restaurants.items;
  if (state.tagFilters.length > 0) {
    items = items.filter(item => item.tags.some(tag => state.tagFilters.includes(tag)));
  }
  return {
    items
  };
};

export default connect(mapStateToProps)(RestaurantList);
