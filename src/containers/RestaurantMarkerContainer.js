import { connect } from 'react-redux';
import { getRestaurantById } from '../selectors/restaurants';
import { getDecision } from '../selectors/decisions';
import { showInfoWindow, hideInfoWindow } from '../actions/mapUi';
import { getMarkerSettingsForId } from '../selectors/mapUi';
import RestaurantMarker from '../components/RestaurantMarker';

const mapStateToProps = (state, ownProps) => {
  const restaurant = getRestaurantById(state, ownProps.id);
  const decision = getDecision(state);
  const decided = decision !== null && decision.restaurant_id === restaurant.id;
  return {
    restaurant,
    decided,
    showInfoWindow: getMarkerSettingsForId(state, ownProps.id).showInfoWindow || false,
    ...ownProps
  };
};

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
