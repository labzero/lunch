import { connect } from 'react-redux';
import RestaurantList from '../../components/RestaurantList';

const mapStateToProps = state => ({ items: state.restaurants.items });

const RestaurantListContainer = connect(mapStateToProps)(RestaurantList);

export default RestaurantListContainer;
