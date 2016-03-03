import { connect } from 'react-redux';
import { addRestaurant } from '../../actions/restaurants';
import RestaurantAddForm from '../../components/RestaurantAddForm';

let myRef;

const setNestedRef = (ref) => {
  myRef = ref;
};

const mapStateToProps = (state) => ({
  refCallback: setNestedRef,
  user: state.user
});

const mapDispatchToProps = (dispatch) => ({
  handleClick: () => {
    dispatch(addRestaurant(myRef.value));
    myRef.value = '';
  }
});

const RestaurantAddFormContainer = connect(mapStateToProps, mapDispatchToProps)(RestaurantAddForm);

export default RestaurantAddFormContainer;
