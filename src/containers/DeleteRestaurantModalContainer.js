import { connect } from 'react-redux';
import { getRestaurantById } from '../selectors/restaurants';
import { removeRestaurant } from '../actions/restaurants';
import { hideModal } from '../actions/modals';
import DeleteRestaurantModal from '../components/DeleteRestaurantModal';

const modalName = 'deleteRestaurant';

const mapStateToProps = state => ({
  restaurant: getRestaurantById(state, state.modals[modalName].restaurantId),
  shown: !!state.modals[modalName].shown
});

const mapDispatchToProps = dispatch => ({
  hideModal: () => {
    dispatch(hideModal(modalName));
  },
  dispatch
});

const mergeProps = (stateProps, dispatchProps) => Object.assign(stateProps, dispatchProps, {
  restaurantName: stateProps.restaurant.name,
  deleteRestaurant: event => {
    event.preventDefault();
    dispatchProps.dispatch(removeRestaurant(stateProps.restaurant.id));
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps,
  mergeProps
)(DeleteRestaurantModal);
