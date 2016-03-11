import React, { Component, PropTypes } from 'react';
import Autosuggest from 'react-autosuggest';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './RestaurantAddTagForm.scss';
import autosuggestTheme from './RestaurantAddTagFormAutosuggest.scss';

class RestaurantAddTagForm extends Component {
  static propTypes = {
    hideAddTagForm: PropTypes.func.isRequired,
    addTagAutosuggestValue: PropTypes.string.isRequired,
    setAddTagAutosuggestValue: PropTypes.func.isRequired,
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
      <form>
        <Autosuggest
          suggestions={this.props.tags}
          getSuggestionValue={this.getSuggestionValue}
          renderSuggestion={this.renderSuggestion}
          inputProps={inputProps}
          theme={autosuggestTheme}
        />
        <button>add</button>
        <button type="button" onClick={this.props.hideAddTagForm}>cancel</button>
      </form>
    );
  }
}

export default withStyles(withStyles(RestaurantAddTagForm, autosuggestTheme), s);
