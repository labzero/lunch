import { connect } from 'react-redux';
import { generateTagList } from '../helpers/TagAutosuggestHelper';
import { showTagFilterForm, hideTagFilterForm } from '../actions/tagUi';
import TagFilterForm from '../components/TagFilterForm';

const mapStateToProps = (state, ownProps) => {
  const tagUi = state.tagUi;
  let tags = state.tags.items;
  const addedTags = state.tagFilters;
  const autosuggestValue = state.tagUi.autosuggestValue || '';
  tags = generateTagList(tags, addedTags, autosuggestValue);
  return {
    ...ownProps,
    addedTags,
    tags,
    autosuggestValue,
    tagUi
  };
};

const mapDispatchToProps = dispatch => ({
  showTagFilterForm() {
    dispatch(showTagFilterForm());
  },
  hideTagFilterForm() {
    dispatch(hideTagFilterForm());
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(TagFilterForm);
