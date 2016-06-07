import { connect } from 'react-redux';
import { getRestaurantById } from '../selectors/restaurants';
import { getListUiItemForId } from '../selectors/listUi';
import { getDecision } from '../selectors/decisions';
import { makeGetAllDecisionCountForRestaurant } from '../selectors';
import { showModal } from '../actions/modals';
import { removeDecision, decide } from '../actions/decisions';
import { showMapAndInfoWindow } from '../actions/mapUi';
import { showEditNameForm, setEditNameFormValue } from '../actions/listUi';
import RestaurantDropdown from '../components/RestaurantDropdown';

const mapStateToProps = () => {
  const getAllDecisionCountForRestaurant = makeGetAllDecisionCountForRestaurant();
  return (state, ownProps) => ({
    restaurant: getRestaurantById(state, ownProps.id),
    listUiItem: getListUiItemForId(state, ownProps.id),
    decision: getDecision(state),
    allDecisionCount: getAllDecisionCountForRestaurant(state, ownProps.id),
    ...ownProps    
  });
};

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
  showMapAndInfoWindow() {
    dispatch(showMapAndInfoWindow(ownProps.id));
  },
  dispatch
});

const mergeProps = (stateProps, dispatchProps, ownProps) => Object.assign({}, stateProps, dispatchProps, {
  showEditNameForm() {
    dispatchProps.dispatch(setEditNameFormValue(ownProps.id, stateProps.restaurant.name));
    dispatchProps.dispatch(showEditNameForm(ownProps.id));
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps,
  mergeProps
)(RestaurantDropdown);
