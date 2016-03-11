import { connect } from 'react-redux';
import { hideAddTagForm, setAddTagAutosuggestValue } from '../../actions/listUi';
import { addNewTagToRestaurant, addTagToRestaurant } from '../../actions/restaurants';
import RestaurantAddTagForm from '../../components/RestaurantAddTagForm';

function escapeRegexCharacters(str) {
  return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

const mapStateToProps = (state, ownProps) => {
  const restaurant = state.restaurants.items.find(r => r.id === ownProps.id);
  let tags = state.tags.items;
  const addedTags = restaurant.tags;
  const listUiItem = state.listUi[restaurant.id] || {};
  const addTagAutosuggestValue = listUiItem.addTagAutosuggestValue || '';
  const escapedValue = escapeRegexCharacters(addTagAutosuggestValue.trim());
  const regex = new RegExp(`^${escapedValue}`, 'i');
  tags = tags
    .filter(tag => !addedTags.includes(tag.id))
    .filter(tag => regex.test(tag.name));
  const shouldRenderSuggestions = () => true;
  return {
    ...ownProps,
    tags,
    addTagAutosuggestValue,
    shouldRenderSuggestions
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
