import { connect } from 'react-redux';
import { removeRestaurant } from '../actions/restaurants';
import { hideModal } from '../actions/modals';
import DeleteRestaurantModal from '../components/DeleteRestaurantModal';

const mapStateToProps = state => ({
  restaurant: state.restaurants.items.find(r => r.id === state.modals.deleteRestaurant.restaurantId),
  shown: !!state.modals.deleteRestaurant.shown
});

const mapDispatchToProps = dispatch => ({
  hideModal() {
    dispatch(hideModal('deleteRestaurant'));
  },
  dispatch
});

const mergeProps = (stateProps, dispatchProps) => Object.assign(stateProps, dispatchProps, {
  shown: stateProps.shown && stateProps.restaurant !== undefined,
  restaurant: stateProps.restaurant || {},
  deleteRestaurant(event) {
    event.preventDefault();
    dispatchProps.dispatch(removeRestaurant(stateProps.restaurant.id));
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps,
  mergeProps
)(DeleteRestaurantModal);
