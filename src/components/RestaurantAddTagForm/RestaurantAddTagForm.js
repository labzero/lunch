import React, { Component, PropTypes } from 'react';
import Autosuggest from 'react-autosuggest';
import { getSuggestionValue, renderSuggestion } from '../../helpers/TagAutosuggestHelper';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './RestaurantAddTagForm.scss';
import autosuggestTheme from './RestaurantAddTagFormAutosuggest.scss';

const returnTrue = () => true;

autosuggestTheme.input = 'form-control input-sm';

export class _RestaurantAddTagForm extends Component {
  componentDidMount() {
    this._input.focus();
  }

  render() {
    return (
      <form className={s.root} onSubmit={this.props.addNewTagToRestaurant}>
        <Autosuggest
          suggestions={this.props.tags}
          focusInputOnSuggestionClick={false}
          getSuggestionValue={getSuggestionValue}
          renderSuggestion={renderSuggestion}
          inputProps={{
            value: this.props.addTagAutosuggestValue,
            onChange: this.props.setAddTagAutosuggestValue,
            ref: i => { this._input = i; }
          }}
          theme={autosuggestTheme}
          onSuggestionSelected={this.props.handleSuggestionSelected}
          shouldRenderSuggestions={returnTrue}
        />
        <button
          className={`btn btn-sm btn-primary ${s.button}`}
          type="submit"
          disabled={this.props.addTagAutosuggestValue === ''}
        >
          add
        </button>
        <button
          className={`btn btn-sm btn-default ${s.button}`}
          type="button"
          onClick={this.props.hideAddTagForm}
        >
          cancel
        </button>
      </form>
    );
  }
}

_RestaurantAddTagForm.propTypes = {
  addNewTagToRestaurant: PropTypes.func.isRequired,
  handleSuggestionSelected: PropTypes.func.isRequired,
  hideAddTagForm: PropTypes.func.isRequired,
  addTagAutosuggestValue: PropTypes.string.isRequired,
  setAddTagAutosuggestValue: PropTypes.func.isRequired,
  tags: PropTypes.array.isRequired
};

export default withStyles(withStyles(_RestaurantAddTagForm, autosuggestTheme), s);
