import { connect } from 'react-redux';
import { addRestaurant } from '../../actions/restaurants';
import RestaurantAddForm from '../../components/RestaurantAddForm';

let myRef;

const setNestedRef = (ref) => {
  myRef = ref;
};

const mapStateToProps = () => ({
  refCallback: setNestedRef
});

const mapDispatchToProps = dispatch => ({
  handleClick: () => {
    dispatch(addRestaurant(myRef.value));
    myRef.value = '';
  }
});

export default connect(mapStateToProps, mapDispatchToProps)(RestaurantAddForm);
