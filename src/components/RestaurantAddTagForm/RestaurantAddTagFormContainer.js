import { connect } from 'react-redux';
import { getRestaurantById } from '../../selectors/restaurants';
import { getTags } from '../../selectors/tags';
import { addNewTagToRestaurant, addTagToRestaurant } from '../../actions/restaurants';
import RestaurantAddTagForm from './RestaurantAddTagForm';

const mapStateToProps = (state, ownProps) => {
  const restaurant = getRestaurantById(state, ownProps.id);
  const addedTags = restaurant.tags;
  const tags = getTags(state);
  return {
    ...ownProps,
    addedTags,
    tags
  };
};

const mapDispatchToProps = (dispatch, ownProps) => ({
  addNewTagToRestaurant: autosuggestValue => {
    dispatch(addNewTagToRestaurant(ownProps.id, autosuggestValue));
  },
  addTagToRestaurant: (id) => {
    dispatch(addTagToRestaurant(ownProps.id, id));
  },
});

export default connect(
  mapStateToProps,
  mapDispatchToProps,
)(RestaurantAddTagForm);
