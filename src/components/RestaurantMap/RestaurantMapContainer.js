import { connect } from 'react-redux';
import {
  clearCenter,
  clearNewlyAdded,
  hideInfoWindow,
  showGoogleInfoWindow,
  showRestaurantInfoWindow
} from '../../actions/mapUi';
import { getRestaurantById } from '../../selectors/restaurants';
import { getTeamLatLng } from '../../selectors/team';
import { getMapUi } from '../../selectors/mapUi';
import { getCurrentUser } from '../../selectors/user';
import { getMapItems } from '../../selectors';
import RestaurantMap from './RestaurantMap';

const mapStateToProps = (state) => {
  const mapUi = getMapUi(state);
  return {
    infoWindow: state.mapUi.infoWindow,
    items: getMapItems(state),
    center: mapUi.center,
    tempMarker: mapUi.tempMarker,
    newlyAddedRestaurant: mapUi.newlyAdded ?
      getRestaurantById(state, mapUi.newlyAdded.id)
      :
      undefined,
    newlyAddedUserId: mapUi.newlyAdded ? mapUi.newlyAdded.userId : undefined,
    latLng: getTeamLatLng(state),
    showPOIs: mapUi.showPOIs,
    user: getCurrentUser(state)
  };
};

const mapDispatchToProps = dispatch => ({
  clearCenter: () => dispatch(clearCenter()),
  mapClicked: ({ event }) => {
    if (!event.target.closest('[data-marker]')) {
      dispatch(hideInfoWindow());
    }
  },
  showGoogleInfoWindow: (event) => dispatch(showGoogleInfoWindow(event)),
  dispatch
});

const mergeProps = (stateProps, dispatchProps) => Object.assign({}, stateProps, dispatchProps, {
  showNewlyAddedInfoWindow: () => {
    if (stateProps.newlyAddedUserId === stateProps.user.id) {
      dispatchProps.dispatch(showRestaurantInfoWindow(stateProps.newlyAddedRestaurant));
      dispatchProps.dispatch(clearNewlyAdded());
    }
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps,
  mergeProps
)(RestaurantMap);
