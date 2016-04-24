import { connect } from 'react-redux';
import { getRestaurantById } from '../selectors/restaurants';
import { showInfoWindow, hideInfoWindow } from '../actions/mapUi';
import { getMarkerSettingsForId } from '../selectors/mapUi';
import RestaurantMarker from '../components/RestaurantMarker';

const mapStateToProps = (state, ownProps) => ({
  restaurant: getRestaurantById(state, ownProps.id),
  showInfoWindow: getMarkerSettingsForId(state, ownProps.id).showInfoWindow || false,
  ...ownProps
});

const mapDispatchToProps = (dispatch) => ({
  dispatch
});

const mergeProps = (stateProps, dispatchProps, ownProps) => Object.assign({}, stateProps, dispatchProps, {
  handleMarkerClick() {
    if (stateProps.showInfoWindow) {
      dispatchProps.dispatch(hideInfoWindow(ownProps.id));
    } else {
      dispatchProps.dispatch(showInfoWindow(ownProps.id, {
        lat: stateProps.restaurant.lat,
        lng: stateProps.restaurant.lng
      }));
    }
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps,
  mergeProps
)(RestaurantMarker);
