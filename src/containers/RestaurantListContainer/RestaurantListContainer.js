import { connect } from 'react-redux';
import RestaurantList from '../../components/RestaurantList';

const mapStateToProps = state => ({ items: state.restaurants.items });

export default connect(mapStateToProps)(RestaurantList);
