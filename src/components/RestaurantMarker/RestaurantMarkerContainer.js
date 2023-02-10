import { connect } from 'react-redux';
import { getRestaurantById } from '../../selectors/restaurants';
import { getDecision } from '../../selectors/decisions';
import { showRestaurantInfoWindow, hideInfoWindow } from '../../actions/mapUi';
import { getMapUi } from '../../selectors/mapUi';
import RestaurantMarker from './RestaurantMarker';

const mapStateToProps = (state, ownProps) => {
  const restaurant = getRestaurantById(state, ownProps.id);
  const decision = getDecision(state);
  const decided = decision !== undefined && decision.restaurant_id === restaurant.id;
  return {
    restaurant,
    decided,
    showInfoWindow: getMapUi(state).infoWindow.id === ownProps.id,
    ...ownProps
  };
};

const mapDispatchToProps = (dispatch) => ({
  dispatch
});

const mergeProps = (stateProps, dispatchProps) => ({
  ...stateProps,
  ...dispatchProps,
  handleMarkerClick(event) {
    event.preventDefault();
    if (stateProps.showInfoWindow) {
      dispatchProps.dispatch(hideInfoWindow());
    } else {
      dispatchProps.dispatch(showRestaurantInfoWindow(stateProps.restaurant));
    }
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps,
  mergeProps
)(RestaurantMarker);
