import { connect } from 'react-redux';
import { getAllOrUnvoted } from '../selectors';
import RestaurantMap from '../components/RestaurantMap';

const mapStateToProps = state => ({
  items: getAllOrUnvoted(state),
  mapUi: state.mapUi,
  latLng: state.latLng
});

export default connect(
  mapStateToProps
)(RestaurantMap);
