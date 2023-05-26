import { connect } from "react-redux";
import { Dispatch, State } from "../../interfaces";
import { getTagsForRestaurant } from "../../selectors/restaurants";
import { removeTagFromRestaurant } from "../../actions/restaurants";
import RestaurantTagList from "./RestaurantTagList";

interface OwnProps {
  id: number;
}

const mapStateToProps = (state: State, ownProps: OwnProps) => ({
  ids: getTagsForRestaurant(state, ownProps.id),
  loggedIn: state.user !== null,
});

const mapDispatchToProps = (dispatch: Dispatch, ownProps: OwnProps) => ({
  removeTag(id: number) {
    dispatch(removeTagFromRestaurant(ownProps.id, id));
  },
});

export default connect(mapStateToProps, mapDispatchToProps)(RestaurantTagList);
