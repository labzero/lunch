import React, { PropTypes } from 'react';
import Autosuggest from 'react-autosuggest';
import TagContainer from '../../containers/TagContainer';
import { getSuggestionValue, renderSuggestion } from '../../helpers/TagAutosuggestHelper';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './TagFilterForm.scss';
import autosuggestTheme from './TagFilterFormAutosuggest.scss';

autosuggestTheme.input = 'form-control input-sm';

const returnTrue = () => true;

const preventDefault = event => event.preventDefault();

export const _TagFilterForm = ({
  autosuggestValue,
  setAutosuggestValue,
  addedTags,
  tags,
  tagUi,
  handleSuggestionSelected,
  showTagFilterForm,
  hideTagFilterForm,
  removeTagFilter
}) => {
  let filterForm;
  let showButton;
  if (tagUi.filterFormShown) {
    filterForm = (
      <form className={s.form} onSubmit={preventDefault}>
        <Autosuggest
          suggestions={tags}
          focusInputOnSuggestionClick={false}
          getSuggestionValue={getSuggestionValue}
          renderSuggestion={renderSuggestion}
          inputProps={{
            value: autosuggestValue,
            onChange: setAutosuggestValue
          }}
          theme={autosuggestTheme}
          onSuggestionSelected={handleSuggestionSelected}
          shouldRenderSuggestions={returnTrue}
        />
        {addedTags.map(tag => {
          const boundRemoveTagFilter = removeTagFilter.bind(undefined, tag);
          return <TagContainer key={`tagFilter_${tag}`} id={tag} showDelete onDeleteClicked={boundRemoveTagFilter} />;
        })}
        <button className={`btn btn-sm btn-default ${s.button}`} type="button" onClick={hideTagFilterForm}>
          Cancel
        </button>
      </form>
    );
  } else {
    showButton = <button onClick={showTagFilterForm}>Filter by tags</button>;
  }
  return (
    <div className={s.root}>{showButton}{filterForm}</div>
  );
};

_TagFilterForm.propTypes = {
  handleSuggestionSelected: PropTypes.func.isRequired,
  removeTagFilter: PropTypes.func.isRequired,
  showTagFilterForm: PropTypes.func.isRequired,
  hideTagFilterForm: PropTypes.func.isRequired,
  autosuggestValue: PropTypes.string.isRequired,
  setAutosuggestValue: PropTypes.func.isRequired,
  addedTags: PropTypes.array.isRequired,
  tags: PropTypes.array.isRequired,
  tagUi: PropTypes.object.isRequired
};

export default withStyles(withStyles(_TagFilterForm, autosuggestTheme), s);
