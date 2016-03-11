import { connect } from 'react-redux';
import { hideAddTagForm, setAddTagAutosuggestValue } from '../../actions/restaurants';
import RestaurantAddTagForm from '../../components/RestaurantAddTagForm';

const mapStateToProps = (state, ownProps) => {
  const restaurant = state.restaurants.items.find(r => r.id === ownProps.id);
  let tags = state.tags.items;
  const addedTags = restaurant.tags;
  tags = tags.filter(tag => !addedTags.includes(tag));
  const addTagAutosuggestValue = restaurant.addTagAutosuggestValue || '';
  return { ...ownProps, tags, addTagAutosuggestValue };
};

const mapDispatchToProps = (dispatch, ownProps) => ({
  hideAddTagForm() {
    dispatch(hideAddTagForm(ownProps.id));
  },
  setAddTagAutosuggestValue(event, { newValue }) {
    dispatch(setAddTagAutosuggestValue(ownProps.id, newValue));
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(RestaurantAddTagForm);
