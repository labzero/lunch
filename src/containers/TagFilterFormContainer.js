import { connect } from 'react-redux';
import { getTagUi } from '../selectors/tagUi';
import { getTagFilters } from '../selectors/tagFilters';
import { makeGetTagList } from '../selectors';
import { showTagFilterForm, hideTagFilterForm, setTagFilterAutosuggestValue } from '../actions/tagUi';
import { addTagFilter, removeTagFilter } from '../actions/tagFilters';
import TagFilterForm from '../components/TagFilterForm';

const mapStateToProps = () => {
  const getTagList = makeGetTagList();
  return (state, ownProps) => {
    const tagUi = getTagUi(state);
    const addedTags = getTagFilters(state);
    const autosuggestValue = tagUi.autosuggestValue || '';
    const tags = getTagList(state, { addedTags, autosuggestValue });
    return {
      ...ownProps,
      addedTags,
      tags,
      autosuggestValue,
      tagUi
    };
  };
};

const mapDispatchToProps = dispatch => ({
  showTagFilterForm() {
    dispatch(showTagFilterForm());
  },
  hideTagFilterForm() {
    dispatch(hideTagFilterForm());
  },
  setAutosuggestValue(event, { newValue }) {
    dispatch(setTagFilterAutosuggestValue(newValue));
  },
  handleSuggestionSelected(event, { suggestion }) {
    dispatch(addTagFilter(suggestion.id));
  },
  removeTagFilter(id) {
    dispatch(removeTagFilter(id));
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(TagFilterForm);
