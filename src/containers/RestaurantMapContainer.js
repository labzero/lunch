import { connect } from 'react-redux';
import { clearCenter, hideAllInfoWindows } from '../actions/mapUi';
import { getMapItems } from '../selectors';
import RestaurantMap from '../components/RestaurantMap';

const mapStateToProps = state => ({
  items: getMapItems(state),
  center: state.mapUi.center,
  tempMarker: state.mapUi.tempMarker,
  latLng: state.latLng,
});

const mapDispatchToProps = dispatch => ({
  clearCenter() {
    dispatch(clearCenter());
  },
  mapClicked({ event }) {
    if (!event.target.closest('[data-marker]')) {
      dispatch(hideAllInfoWindows());
    }
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(RestaurantMap);
