import { connect } from 'react-redux';
import { getRestaurantById } from '../selectors/restaurants';
import { getListUiItemForId } from '../selectors/listUi';
import { getDecision } from '../selectors/decisions';
import { showModal } from '../actions/modals';
import { removeDecision, decide } from '../actions/decisions';
import { showMapAndInfoWindow } from '../actions/mapUi';
import { showEditNameForm, setEditNameFormValue } from '../actions/listUi';
import RestaurantDropdown from '../components/RestaurantDropdown';

const mapStateToProps = (state, ownProps) => ({
  restaurant: getRestaurantById(state, ownProps.id),
  listUiItem: getListUiItemForId(state, ownProps.id),
  decision: getDecision(state),
  ...ownProps
});

const mapDispatchToProps = (dispatch, ownProps) => ({
  deleteRestaurant: () => {
    dispatch(showModal('deleteRestaurant', { restaurantId: ownProps.id }));
  },
  removeDecision: () => {
    dispatch(removeDecision());
  },
  decide: () => {
    dispatch(decide(ownProps.id));
  },
  dispatch
});

const mergeProps = (stateProps, dispatchProps, ownProps) => Object.assign({}, stateProps, dispatchProps, {
  showEditNameForm() {
    dispatchProps.dispatch(setEditNameFormValue(ownProps.id, stateProps.restaurant.name));
    dispatchProps.dispatch(showEditNameForm(ownProps.id));
  },
  showMapAndInfoWindow() {
    dispatchProps.dispatch(showMapAndInfoWindow(ownProps.id, {
      lat: stateProps.restaurant.lat,
      lng: stateProps.restaurant.lng
    }));
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps,
  mergeProps
)(RestaurantDropdown);
