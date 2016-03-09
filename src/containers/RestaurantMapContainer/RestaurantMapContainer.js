import { connect } from 'react-redux';
import RestaurantMap from '../../components/RestaurantMap';

const mapStateToProps = state => ({
  items: state.restaurants.items,
  latLng: state.latLng
});

export default connect(
  mapStateToProps
)(RestaurantMap);
