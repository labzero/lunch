import { connect } from "react-redux";
import { getRestaurantById } from "../../selectors/restaurants";
import { getListUiItemForId } from "../../selectors/listUi";
import { showMapAndInfoWindow } from "../../actions/mapUi";
import Restaurant from "./Restaurant";

const mapStateToProps = (state, ownProps) => ({
  restaurant: getRestaurantById(state, ownProps.id),
  loggedIn: state.user.id !== undefined,
  listUiItem: getListUiItemForId(state, ownProps.id),
  ...ownProps,
});

const mapDispatchToProps = (dispatch, ownProps) => ({
  showMapAndInfoWindow: () => {
    dispatch(showMapAndInfoWindow(ownProps.id));
  },
  dispatch,
});

export default connect(mapStateToProps, mapDispatchToProps)(Restaurant);
