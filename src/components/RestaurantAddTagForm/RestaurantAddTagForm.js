import React, { Component, PropTypes } from 'react';
import Autosuggest from 'react-autosuggest';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './RestaurantAddTagForm.scss';
import autosuggestTheme from './RestaurantAddTagFormAutosuggest.scss';

class RestaurantAddTagForm extends Component {
  static propTypes = {
    addNewTagToRestaurant: PropTypes.func.isRequired,
    handleSuggestionSelected: PropTypes.func.isRequired,
    hideAddTagForm: PropTypes.func.isRequired,
    addTagAutosuggestValue: PropTypes.string.isRequired,
    setAddTagAutosuggestValue: PropTypes.func.isRequired,
    shouldRenderSuggestions: PropTypes.func.isRequired,
    tags: PropTypes.array.isRequired
  }

  getSuggestionValue(suggestion) {
    return suggestion.name;
  }

  renderSuggestion(suggestion) {
    return <span>{suggestion.name}</span>;
  }

  render() {
    const inputProps = {
      value: this.props.addTagAutosuggestValue,
      onChange: this.props.setAddTagAutosuggestValue
    };

    return (
      <form className={s.root} onSubmit={this.props.addNewTagToRestaurant}>
        <Autosuggest
          suggestions={this.props.tags}
          focusInputOnSuggestionClick={false}
          getSuggestionValue={this.getSuggestionValue}
          renderSuggestion={this.renderSuggestion}
          inputProps={inputProps}
          theme={autosuggestTheme}
          onSuggestionSelected={this.props.handleSuggestionSelected}
          shouldRenderSuggestions={this.props.shouldRenderSuggestions}
        />
        <button className={s.button} type="button" onClick={this.props.addNewTagToRestaurant}>add</button>
        <button className={s.button} type="button" onClick={this.props.hideAddTagForm}>cancel</button>
      </form>
    );
  }
}

export default withStyles(withStyles(RestaurantAddTagForm, autosuggestTheme), s);
