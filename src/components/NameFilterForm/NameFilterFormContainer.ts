import { connect } from "react-redux";
import { setFlipMove } from "../../actions/listUi";
import { setNameFilter } from "../../actions/restaurants";
import { Dispatch, State } from "../../interfaces";
import { getNameFilter, getRestaurantIds } from "../../selectors/restaurants";
import NameFilterForm from "./NameFilterForm";

const mapStateToProps = (state: State) => ({
  nameFilter: getNameFilter(state),
  restaurantIds: getRestaurantIds(state),
});

const mapDispatchToProps = (dispatch: Dispatch) => ({
  setFlipMove: (val: boolean) => dispatch(setFlipMove(val)),
  setNameFilter: (val: string) => dispatch(setNameFilter(val)),
});

export default connect(mapStateToProps, mapDispatchToProps)(NameFilterForm);
