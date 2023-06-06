import { connect } from "react-redux";
import { showMapAndInfoWindow } from "../../actions/mapUi";
import { Dispatch, State } from "../../interfaces";
import { getListUiItemForId } from "../../selectors/listUi";
import { getRestaurantById } from "../../selectors/restaurants";
import Restaurant, { RestaurantProps } from "./Restaurant";

interface OwnProps
  extends Pick<RestaurantProps, "shouldShowAddTagArea" | "shouldShowDropdown"> {
  id: number;
}

const mapStateToProps = (state: State, ownProps: OwnProps) => ({
  restaurant: getRestaurantById(state, ownProps.id),
  loggedIn: state.user !== null,
  listUiItem: getListUiItemForId(state, ownProps.id),
  ...ownProps,
});

const mapDispatchToProps = (dispatch: Dispatch, ownProps: OwnProps) => ({
  showMapAndInfoWindow: () => {
    dispatch(showMapAndInfoWindow(ownProps.id));
  },
  dispatch,
});

export default connect(mapStateToProps, mapDispatchToProps)(Restaurant);
