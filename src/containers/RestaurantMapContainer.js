import { connect } from 'react-redux';
import { clearCenter, hideAllInfoWindows, showInfoWindow, clearNewlyAdded } from '../actions/mapUi';
import { getRestaurantById } from '../selectors/restaurants';
import { getMapUi } from '../selectors/mapUi';
import { getCurrentUser } from '../selectors/user';
import { getMapItems } from '../selectors';
import RestaurantMap from '../components/RestaurantMap';

const mapStateToProps = state => {
  const mapUi = getMapUi(state);
  return {
    items: getMapItems(state),
    center: mapUi.center,
    tempMarker: mapUi.tempMarker,
    newlyAddedRestaurant: mapUi.newlyAdded ? getRestaurantById(state, mapUi.newlyAdded.id) : undefined,
    newlyAddedUserId: mapUi.newlyAdded ? mapUi.newlyAdded.userId : undefined,
    latLng: state.latLng,
    user: getCurrentUser(state)
  };
};

const mapDispatchToProps = dispatch => ({
  clearCenter() {
    dispatch(clearCenter());
  },
  mapClicked({ event }) {
    if (!event.target.closest('[data-marker]')) {
      dispatch(hideAllInfoWindows());
    }
  },
  dispatch
});

const mergeProps = (stateProps, dispatchProps) => Object.assign({}, stateProps, dispatchProps, {
  showNewlyAddedInfoWindow() {
    if (stateProps.newlyAddedUserId === stateProps.user.id) {
      dispatchProps.dispatch(showInfoWindow(stateProps.newlyAddedRestaurant));
      dispatchProps.dispatch(clearNewlyAdded());
    }
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps,
  mergeProps
)(RestaurantMap);
