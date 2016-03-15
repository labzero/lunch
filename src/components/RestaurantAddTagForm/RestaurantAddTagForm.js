import React, { PropTypes } from 'react';
import Autosuggest from 'react-autosuggest';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './RestaurantAddTagForm.scss';
import autosuggestTheme from './RestaurantAddTagFormAutosuggest.scss';

const RestaurantAddTagForm = ({
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
      getSuggestionValue={RestaurantAddTagForm.getSuggestionValue}
      renderSuggestion={RestaurantAddTagForm.renderSuggestion}
      inputProps={{
        value: addTagAutosuggestValue,
        onChange: setAddTagAutosuggestValue
      }}
      theme={autosuggestTheme}
      onSuggestionSelected={handleSuggestionSelected}
      shouldRenderSuggestions={shouldRenderSuggestions}
    />
    <button className={s.button} type="button" onClick={addNewTagToRestaurant}>add</button>
    <button className={s.button} type="button" onClick={hideAddTagForm}>cancel</button>
  </form>
);

RestaurantAddTagForm.getSuggestionValue = suggestion => suggestion.name;
RestaurantAddTagForm.renderSuggestion = suggestion => <span>{suggestion.name}</span>;
RestaurantAddTagForm.propTypes = {
  addNewTagToRestaurant: PropTypes.func.isRequired,
  handleSuggestionSelected: PropTypes.func.isRequired,
  hideAddTagForm: PropTypes.func.isRequired,
  addTagAutosuggestValue: PropTypes.string.isRequired,
  setAddTagAutosuggestValue: PropTypes.func.isRequired,
  shouldRenderSuggestions: PropTypes.func.isRequired,
  tags: PropTypes.array.isRequired
};

export default withStyles(withStyles(RestaurantAddTagForm, autosuggestTheme), s);
