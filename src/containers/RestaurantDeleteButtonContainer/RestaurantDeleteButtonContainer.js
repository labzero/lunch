import { connect } from 'react-redux';
import { removeRestaurant } from '../../actions/restaurants';
import RestaurantDeleteButton from '../../components/RestaurantDeleteButton';

const mapStateToProps = null;

const mapDispatchToProps = (dispatch, ownProps) => ({
  handleClick: () => {
    dispatch(removeRestaurant(ownProps.id));
  }
});

const RestaurantDeleteButtonContainer = connect(
  mapStateToProps,
  mapDispatchToProps
)(RestaurantDeleteButton);

export default RestaurantDeleteButtonContainer;
