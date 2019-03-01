import { connect } from 'react-redux';
import { getRestaurantById } from '../../selectors/restaurants';
import { getListUiItemForId } from '../../selectors/listUi';
import { getDecision, getDecisionsByRestaurantId } from '../../selectors/decisions';
import { showModal } from '../../actions/modals';
import { removeDecision } from '../../actions/decisions';
import { showMapAndInfoWindow } from '../../actions/mapUi';
import { showEditNameForm, setEditNameFormValue } from '../../actions/listUi';
import { removeRestaurant } from '../../actions/restaurants';
import { getTeamSortDuration } from '../../selectors/team';
import RestaurantDropdown from './RestaurantDropdown';

const mapStateToProps = (state, ownProps) => ({
  restaurant: getRestaurantById(state, ownProps.id),
  sortDuration: getTeamSortDuration(state),
  listUiItem: getListUiItemForId(state, ownProps.id),
  decision: getDecision(state),
  pastDecisions: getDecisionsByRestaurantId(state),
  ...ownProps
});

const mapDispatchToProps = (dispatch, ownProps) => ({
  removeDecision: () => {
    dispatch(removeDecision());
  },
  showPastDecisionsModal: () => {
    dispatch(showModal('pastDecisions', {
      restaurantId: ownProps.id
    }));
  },
  showMapAndInfoWindow: () => {
    dispatch(showMapAndInfoWindow(ownProps.id));
  },
  dispatch
});

const mergeProps = (stateProps, dispatchProps, ownProps) => Object.assign({}, stateProps, dispatchProps, {
  deleteRestaurant: () => dispatchProps.dispatch(showModal('confirm', {
    actionLabel: 'Delete',
    body: `Are you sure you want to delete ${stateProps.restaurant.name}?`,
    handleSubmit: () => dispatchProps.dispatch(removeRestaurant(ownProps.id))
  })),
  showEditNameForm: () => {
    dispatchProps.dispatch(setEditNameFormValue(ownProps.id, stateProps.restaurant.name));
    dispatchProps.dispatch(showEditNameForm(ownProps.id));
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps,
  mergeProps
)(RestaurantDropdown);
