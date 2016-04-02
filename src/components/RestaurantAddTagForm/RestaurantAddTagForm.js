import React, { PropTypes } from 'react';
import Autosuggest from 'react-autosuggest';
import { getSuggestionValue, renderSuggestion } from '../../helpers/TagAutosuggestHelper';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './RestaurantAddTagForm.scss';
import autosuggestTheme from './RestaurantAddTagFormAutosuggest.scss';

const returnTrue = () => true;

autosuggestTheme.input = 'form-control input-sm';

export const _RestaurantAddTagForm = ({
  addTagAutosuggestValue,
  setAddTagAutosuggestValue,
  addNewTagToRestaurant,
  tags,
  handleSuggestionSelected,
  hideAddTagForm
}) => (
  <form className={s.root} onSubmit={addNewTagToRestaurant}>
    <Autosuggest
      suggestions={tags}
      focusInputOnSuggestionClick={false}
      getSuggestionValue={getSuggestionValue}
      renderSuggestion={renderSuggestion}
      inputProps={{
        value: addTagAutosuggestValue,
        onChange: setAddTagAutosuggestValue
      }}
      theme={autosuggestTheme}
      onSuggestionSelected={handleSuggestionSelected}
      shouldRenderSuggestions={returnTrue}
    />
    <button
      className={`btn btn-sm btn-primary ${s.button}`}
      type="button"
      disabled={addTagAutosuggestValue === ''}
      onClick={addNewTagToRestaurant}
    >
      add
    </button>
    <button className={`btn btn-sm btn-default ${s.button}`} type="button" onClick={hideAddTagForm}>cancel</button>
  </form>
);

_RestaurantAddTagForm.propTypes = {
  addNewTagToRestaurant: PropTypes.func.isRequired,
  handleSuggestionSelected: PropTypes.func.isRequired,
  hideAddTagForm: PropTypes.func.isRequired,
  addTagAutosuggestValue: PropTypes.string.isRequired,
  setAddTagAutosuggestValue: PropTypes.func.isRequired,
  tags: PropTypes.array.isRequired
};

export default withStyles(withStyles(_RestaurantAddTagForm, autosuggestTheme), s);
