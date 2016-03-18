import React, { PropTypes } from 'react';
import Autosuggest from 'react-autosuggest';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './RestaurantAddTagForm.scss';
import autosuggestTheme from './RestaurantAddTagFormAutosuggest.scss';

export const _RestaurantAddTagForm = ({
  addTagAutosuggestValue,
  setAddTagAutosuggestValue,
  addNewTagToRestaurant,
  tags,
  handleSuggestionSelected,
  shouldRenderSuggestions,
  hideAddTagForm
}) => (
  <form className={s.root} onSubmit={addNewTagToRestaurant}>
    <Autosuggest
      suggestions={tags}
      focusInputOnSuggestionClick={false}
      getSuggestionValue={_RestaurantAddTagForm.getSuggestionValue}
      renderSuggestion={_RestaurantAddTagForm.renderSuggestion}
      inputProps={{
        value: addTagAutosuggestValue,
        onChange: setAddTagAutosuggestValue
      }}
      theme={autosuggestTheme}
      onSuggestionSelected={handleSuggestionSelected}
      shouldRenderSuggestions={shouldRenderSuggestions}
    />
    <button
      className={s.button}
      type="button"
      disabled={addTagAutosuggestValue === ''}
      onClick={addNewTagToRestaurant}
    >
      add
    </button>
    <button className={s.button} type="button" onClick={hideAddTagForm}>cancel</button>
  </form>
);

_RestaurantAddTagForm.getSuggestionValue = suggestion => suggestion.name;
_RestaurantAddTagForm.renderSuggestion = suggestion => <span>{suggestion.name}</span>;
_RestaurantAddTagForm.propTypes = {
  addNewTagToRestaurant: PropTypes.func.isRequired,
  handleSuggestionSelected: PropTypes.func.isRequired,
  hideAddTagForm: PropTypes.func.isRequired,
  addTagAutosuggestValue: PropTypes.string.isRequired,
  setAddTagAutosuggestValue: PropTypes.func.isRequired,
  shouldRenderSuggestions: PropTypes.func.isRequired,
  tags: PropTypes.array.isRequired
};

export default withStyles(withStyles(_RestaurantAddTagForm, autosuggestTheme), s);
