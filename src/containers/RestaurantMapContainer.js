import { connect } from 'react-redux';
import { getMapItems } from '../selectors';
import RestaurantMap from '../components/RestaurantMap';

const mapStateToProps = state => ({
  items: getMapItems(state),
  mapUi: state.mapUi,
  latLng: state.latLng
});

export default connect(
  mapStateToProps
)(RestaurantMap);
