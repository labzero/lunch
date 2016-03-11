import { connect } from 'react-redux';
import { showInfoWindow, hideInfoWindow } from '../../actions/mapUi';
import RestaurantMap from '../../components/RestaurantMap';

const mapStateToProps = state => ({
  items: state.restaurants.items,
  mapUi: state.mapUi,
  latLng: state.latLng
});

const mapDispatchToProps = dispatch => ({
  handleMarkerClick(id) {
    dispatch(showInfoWindow(id));
  },
  handleMarkerClose(id) {
    dispatch(hideInfoWindow(id));
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(RestaurantMap);
