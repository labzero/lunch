import { connect } from 'react-redux';
import { addRestaurant } from '../../actions/restaurants';
import GoogleInfoWindow from './GoogleInfoWindow';

const mapDispatchToProps = (dispatch, ownProps) => ({
  addRestaurant: (result) => {
    const { name, formatted_address } = result;
    const location = result.geometry.location;

    return dispatch(addRestaurant(
      name,
      ownProps.placeId,
      formatted_address,
      location.lat(),
      location.lng()
    ));
  }
});

export default connect(null, mapDispatchToProps)(GoogleInfoWindow);
