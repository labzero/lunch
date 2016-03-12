import { connect } from 'react-redux';
import { removeRestaurant } from '../actions/restaurants';
import RestaurantDeleteButton from '../components/RestaurantDeleteButton';

const mapStateToProps = null;

const mapDispatchToProps = (dispatch, ownProps) => ({
  handleClick: () => {
    if (confirm('Are you sure you want to delete this restaurant?')) {
      dispatch(removeRestaurant(ownProps.id));
    }
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(RestaurantDeleteButton);
