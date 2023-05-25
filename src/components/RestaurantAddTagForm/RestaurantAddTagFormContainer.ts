import { connect } from "react-redux";
import { getRestaurantById } from "../../selectors/restaurants";
import { getTags } from "../../selectors/tags";
import {
  addNewTagToRestaurant,
  addTagToRestaurant,
} from "../../actions/restaurants";
import { Dispatch, State } from "../../interfaces";
import RestaurantAddTagForm from "./RestaurantAddTagForm";

interface OwnProps {
  hideAddTagForm: () => void;
  id: number;
}

const mapStateToProps = (state: State, ownProps: OwnProps) => {
  const restaurant = getRestaurantById(state, ownProps.id);
  const addedTags = restaurant.tags;
  const tags = getTags(state);
  return {
    ...ownProps,
    addedTags,
    tags,
  };
};

const mapDispatchToProps = (dispatch: Dispatch, ownProps: OwnProps) => ({
  addNewTagToRestaurant: (autosuggestValue: string) => {
    dispatch(addNewTagToRestaurant(ownProps.id, autosuggestValue));
  },
  addTagToRestaurant: (id: number) => {
    dispatch(addTagToRestaurant(ownProps.id, id));
  },
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(RestaurantAddTagForm);
