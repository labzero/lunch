import { connect } from 'react-redux';
import { hideAddTagForm, setAddTagAutosuggestValue } from '../actions/listUi';
import { addNewTagToRestaurant, addTagToRestaurant } from '../actions/restaurants';
import { generateTagList } from '../helpers/TagAutosuggestHelper';
import RestaurantAddTagForm from '../components/RestaurantAddTagForm';

const mapStateToProps = (state, ownProps) => {
  const restaurant = state.restaurants.items.find(r => r.id === ownProps.id);
  let tags = state.tags.items;
  const addedTags = restaurant.tags;
  const listUiItem = state.listUi[restaurant.id] || {};
  const addTagAutosuggestValue = listUiItem.addTagAutosuggestValue || '';
  tags = generateTagList(tags, addedTags, addTagAutosuggestValue);
  return {
    ...ownProps,
    tags,
    addTagAutosuggestValue
  };
};

const mapDispatchToProps = (dispatch, ownProps) => ({
  handleSuggestionSelected(event, { suggestion }) {
    dispatch(addTagToRestaurant(ownProps.id, suggestion.id));
  },
  hideAddTagForm() {
    dispatch(hideAddTagForm(ownProps.id));
  },
  setAddTagAutosuggestValue(event, { newValue }) {
    dispatch(setAddTagAutosuggestValue(ownProps.id, newValue));
  },
  dispatch
});

const mergeProps = (stateProps, dispatchProps, ownProps) => Object.assign({}, stateProps, dispatchProps, {
  addNewTagToRestaurant() {
    dispatchProps.dispatch(addNewTagToRestaurant(ownProps.id, stateProps.addTagAutosuggestValue));
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps,
  mergeProps
)(RestaurantAddTagForm);
