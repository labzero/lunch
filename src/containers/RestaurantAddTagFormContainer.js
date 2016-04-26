import { connect } from 'react-redux';
import { getRestaurantById } from '../selectors/restaurants';
import { getListUiItemForId } from '../selectors/listUi';
import { makeGetTagList } from '../selectors';
import { hideAddTagForm, setAddTagAutosuggestValue } from '../actions/listUi';
import { addNewTagToRestaurant, addTagToRestaurant } from '../actions/restaurants';
import RestaurantAddTagForm from '../components/RestaurantAddTagForm';

const mapStateToProps = () => {
  const getTagList = makeGetTagList();
  return (state, ownProps) => {
    const restaurant = getRestaurantById(state, ownProps.id);
    const addedTags = restaurant.tags;
    const listUiItem = getListUiItemForId(state, ownProps.id);
    const autosuggestValue = listUiItem.addTagAutosuggestValue || '';
    const tags = getTagList(state, { addedTags, autosuggestValue });
    return {
      ...ownProps,
      tags,
      autosuggestValue
    };
  };
};

const mapDispatchToProps = (dispatch, ownProps) => ({
  handleSuggestionSelected(event, { suggestion, method }) {
    if (method === 'enter') {
      event.preventDefault();
    }
    dispatch(addTagToRestaurant(ownProps.id, suggestion.id));
  },
  hideAddTagForm() {
    dispatch(hideAddTagForm(ownProps.id));
  },
  setAddTagAutosuggestValue(event, { newValue, method }) {
    if (method === 'up' || method === 'down') {
      return;
    }
    dispatch(setAddTagAutosuggestValue(ownProps.id, newValue));
  },
  dispatch
});

const mergeProps = (stateProps, dispatchProps, ownProps) => Object.assign({}, stateProps, dispatchProps, {
  addNewTagToRestaurant(event) {
    event.preventDefault();
    dispatchProps.dispatch(addNewTagToRestaurant(ownProps.id, stateProps.autosuggestValue));
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps,
  mergeProps
)(RestaurantAddTagForm);
