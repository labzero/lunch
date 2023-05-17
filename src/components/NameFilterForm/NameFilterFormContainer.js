import { connect } from "react-redux";
import { setFlipMove } from "../../actions/listUi";
import { setNameFilter } from "../../actions/restaurants";
import { getNameFilter, getRestaurantIds } from "../../selectors/restaurants";
import NameFilterForm from "./NameFilterForm";

const mapStateToProps = (state) => ({
  nameFilter: getNameFilter(state),
  restaurantIds: getRestaurantIds(state),
});

const mapDispatchToProps = (dispatch) => ({
  setFlipMove: (val) => dispatch(setFlipMove(val)),
  setNameFilter: (val) => dispatch(setNameFilter(val)),
});

export default connect(mapStateToProps, mapDispatchToProps)(NameFilterForm);
