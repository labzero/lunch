import { connect } from "react-redux";
import { addRestaurant } from "../../actions/restaurants";
import { Dispatch } from "../../interfaces";
import GoogleInfoWindow from "./GoogleInfoWindow";

const mapDispatchToProps = (
  dispatch: Dispatch,
  ownProps: { placeId: string }
) => ({
  addRestaurant: (result: google.maps.places.PlaceResult) => {
    // eslint-disable-next-line camelcase
    const { name, formatted_address } = result;
    const location = result.geometry?.location;

    return dispatch(
      addRestaurant(
        name || "",
        ownProps.placeId,
        // eslint-disable-next-line camelcase
        formatted_address || "",
        location?.lat() || 0,
        location?.lng() || 0
      )
    );
  },
});

export default connect(null, mapDispatchToProps)(GoogleInfoWindow);
