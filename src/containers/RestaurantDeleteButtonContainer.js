import { connect } from 'react-redux';
import { showModal } from '../actions/modals';
import RestaurantDeleteButton from '../components/RestaurantDeleteButton';

const mapStateToProps = null;

const mapDispatchToProps = (dispatch, ownProps) => ({
  handleClick: () => {
    dispatch(showModal('deleteRestaurant', ownProps.id));
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(RestaurantDeleteButton);
