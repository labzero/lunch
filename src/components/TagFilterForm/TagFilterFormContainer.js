import { connect } from 'react-redux';
import { getRestaurantIds } from '../../selectors/restaurants';
import { getTagFilters } from '../../selectors/tagFilters';
import { getTagExclusions } from '../../selectors/tagExclusions';
import { getTags } from '../../selectors/tags';
import { addTagFilter, clearTagFilters, removeTagFilter } from '../../actions/tagFilters';
import { addTagExclusion, clearTagExclusions, removeTagExclusion } from '../../actions/tagExclusions';
import TagFilterForm from './TagFilterForm';

const mapStateToProps = (state, ownProps) => {
  let addedTags;
  if (ownProps.exclude) {
    addedTags = getTagExclusions(state);
  } else {
    addedTags = getTagFilters(state);
  }
  return {
    ...ownProps,
    allTags: getTags(state),
    addedTags,
    restaurantIds: getRestaurantIds(state),
  };
};

const mapDispatchToProps = (dispatch, ownProps) => ({
  clearTags() {
    if (ownProps.exclude) {
      dispatch(clearTagExclusions());
    } else {
      dispatch(clearTagFilters());
    }
  },
  addTag(id) {
    if (ownProps.exclude) {
      dispatch(addTagExclusion(id));
    } else {
      dispatch(addTagFilter(id));
    }
  },
  handleSuggestionSelected(event, { suggestion, method }) {
    if (method === 'enter') {
      event.preventDefault();
    }
    if (ownProps.exclude) {
      dispatch(addTagExclusion(suggestion.id));
    } else {
      dispatch(addTagFilter(suggestion.id));
    }
  },
  removeTag(id) {
    if (ownProps.exclude) {
      dispatch(removeTagExclusion(id));
    } else {
      dispatch(removeTagFilter(id));
    }
  },
  dispatch
});

const mergeProps = (stateProps, dispatchProps, ownProps) =>
  Object.assign({}, stateProps, dispatchProps, {
    addByName(event) {
      event.preventDefault();
      const tag = stateProps.tags.find(t => t.name === stateProps.autosuggestValue);
      if (tag !== undefined) {
        if (ownProps.exclude) {
          dispatchProps.dispatch(addTagExclusion(tag.id));
        } else {
          dispatchProps.dispatch(addTagFilter(tag.id));
        }
      }
    }
  });

export default connect(
  mapStateToProps,
  mapDispatchToProps,
  mergeProps
)(TagFilterForm);
