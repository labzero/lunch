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
  setAutosuggestValue(event, { newValue }) {
    if (ownProps.exclude) {
      dispatch(setTagExclusionAutosuggestValue(newValue));
    } else {
      dispatch(setTagFilterAutosuggestValue(newValue));
    }
  },
  handleSuggestionSelected(event, { suggestion }) {
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
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(TagFilterForm);
