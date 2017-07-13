import PropTypes from 'prop-types';
import React, { Component } from 'react';
import Autosuggest from 'react-autosuggest';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import { generateTagList, getSuggestionValue, renderSuggestion } from '../../helpers/TagAutosuggestHelper';
import s from './RestaurantAddTagForm.scss';

// eslint-disable-next-line css-modules/no-unused-class
import autosuggestTheme from './RestaurantAddTagFormAutosuggest.scss';

const returnTrue = () => true;

// eslint-disable-next-line css-modules/no-undef-class
autosuggestTheme.input = 'form-control input-sm';

export class _RestaurantAddTagForm extends Component {
  static propTypes = {
    addedTags: PropTypes.array.isRequired,
    addNewTagToRestaurant: PropTypes.func.isRequired,
    addTagToRestaurant: PropTypes.func.isRequired,
    hideAddTagForm: PropTypes.func.isRequired,
    tags: PropTypes.array.isRequired
  };

  state = {
    autosuggestValue: ''
  };

  componentDidMount() {
    this.autosuggest.input.focus();
  }

  setAddTagAutosuggestValue = (event, { newValue, method }) => {
    if (method === 'up' || method === 'down') {
      return;
    }
    this.setState(() => ({
      autosuggestValue: newValue,
    }));
  };

  handleSubmit = (event) => {
    event.preventDefault();
    this.props.addNewTagToRestaurant(this.state.autosuggestValue);
    this.setState(() => ({
      autosuggestValue: '',
    }));
  }

  handleSuggestionSelected = (event, { suggestion, method }) => {
    if (method === 'enter') {
      event.preventDefault();
    }
    this.props.addTagToRestaurant(suggestion.id);
    this.setState(() => ({
      autosuggestValue: '',
    }));
  };

  render() {
    const {
      addedTags,
      hideAddTagForm,
      tags,
    } = this.props;

    const { autosuggestValue } = this.state;

    const filteredTags = generateTagList(tags, addedTags, autosuggestValue);

    return (
      <form className={s.root} onSubmit={this.handleSubmit}>
        <Autosuggest
          suggestions={filteredTags}
          focusInputOnSuggestionClick={false}
          getSuggestionValue={getSuggestionValue}
          renderSuggestion={renderSuggestion}
          inputProps={{
            value: autosuggestValue,
            onChange: this.setAddTagAutosuggestValue,
          }}
          theme={autosuggestTheme}
          onSuggestionSelected={this.handleSuggestionSelected}
          onSuggestionsFetchRequested={() => {}}
          onSuggestionsClearRequested={() => {}}
          shouldRenderSuggestions={returnTrue}
          ref={a => { this.autosuggest = a; }}
        />
        <button
          className={`btn btn-sm btn-primary ${s.button}`}
          type="submit"
          disabled={autosuggestValue === ''}
        >
          add
        </button>
        <button
          className={`btn btn-sm btn-default ${s.button}`}
          type="button"
          onClick={hideAddTagForm}
        >
          done
        </button>
      </form>
    );
  }
}

export default withStyles(s)(withStyles(autosuggestTheme)(_RestaurantAddTagForm));
