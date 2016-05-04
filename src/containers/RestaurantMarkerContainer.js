import { connect } from 'react-redux';
import { getRestaurantById } from '../selectors/restaurants';
import { getDecision } from '../selectors/decisions';
import { showInfoWindow, hideInfoWindow } from '../actions/mapUi';
import { getMapUi } from '../selectors/mapUi';
import RestaurantMarker from '../components/RestaurantMarker';

const mapStateToProps = (state, ownProps) => {
  const restaurant = getRestaurantById(state, ownProps.id);
  const decision = getDecision(state);
  const decided = decision !== null && decision.restaurant_id === restaurant.id;
  return {
    restaurant,
    decided,
    showInfoWindow: getMapUi(state).infoWindowId === ownProps.id,
    ...ownProps
  };
};

const mapDispatchToProps = (dispatch) => ({
  dispatch
});

const mergeProps = (stateProps, dispatchProps) => Object.assign({}, stateProps, dispatchProps, {
  handleMarkerClick() {
    if (stateProps.showInfoWindow) {
      dispatchProps.dispatch(hideInfoWindow());
    } else {
      dispatchProps.dispatch(showInfoWindow(stateProps.restaurant));
    }
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps,
  mergeProps
)(RestaurantMarker);
