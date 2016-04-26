import { connect } from 'react-redux';
import { getTagUi } from '../selectors/tagUi';
import { getTagFilters } from '../selectors/tagFilters';
import { getTagExclusions } from '../selectors/tagExclusions';
import { makeGetTagList } from '../selectors';
import {
  showTagFilterForm,
  hideTagFilterForm,
  setTagFilterAutosuggestValue,
  showTagExclusionForm,
  hideTagExclusionForm,
  setTagExclusionAutosuggestValue,
} from '../actions/tagUi';
import { addTagFilter, removeTagFilter } from '../actions/tagFilters';
import { addTagExclusion, removeTagExclusion } from '../actions/tagExclusions';
import TagFilterForm from '../components/TagFilterForm';

const mapStateToProps = () => {
  const getTagList = makeGetTagList();
  return (state, ownProps) => {
    const tagUi = getTagUi(state);
    let tagUiForm;
    let addedTags;
    if (ownProps.exclude) {
      tagUiForm = tagUi.exclusionForm;
      addedTags = getTagExclusions(state);
    } else {
      tagUiForm = tagUi.filterForm;
      addedTags = getTagFilters(state);
    }
    const autosuggestValue = tagUiForm.autosuggestValue || '';
    const tags = getTagList(state, { addedTags, autosuggestValue });
    return {
      ...ownProps,
      addedTags,
      tags,
      autosuggestValue,
      tagUiForm
    };
  };
};

const mapDispatchToProps = (dispatch, ownProps) => ({
  showForm() {
    if (ownProps.exclude) {
      dispatch(showTagExclusionForm());
    } else {
      dispatch(showTagFilterForm());
    }
  },
  hideForm() {
    if (ownProps.exclude) {
      dispatch(hideTagExclusionForm());
    } else {
      dispatch(hideTagFilterForm());
    }
  },
  setAutosuggestValue(event, { newValue, method }) {
    if (method === 'up' || method === 'down') {
      return;
    }
    if (ownProps.exclude) {
      dispatch(setTagExclusionAutosuggestValue(newValue));
    } else {
      dispatch(setTagFilterAutosuggestValue(newValue));
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

const mergeProps = (stateProps, dispatchProps, ownProps) => Object.assign({}, stateProps, dispatchProps, {
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
