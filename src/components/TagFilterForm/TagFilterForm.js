import PropTypes from 'prop-types';
import React, { Component } from 'react';
import Autosuggest from 'react-autosuggest';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import TagContainer from '../Tag/TagContainer';
import { generateTagList, getSuggestionValue, renderSuggestion } from '../../helpers/TagAutosuggestHelper';
import s from './TagFilterForm.scss';

// eslint-disable-next-line css-modules/no-unused-class
import autosuggestTheme from './TagFilterFormAutosuggest.scss';

// eslint-disable-next-line css-modules/no-undef-class
autosuggestTheme.input = 'form-control';

const returnTrue = () => true;

class TagFilterForm extends Component {
  static propTypes = {
    exclude: PropTypes.bool,
    addByName: PropTypes.func.isRequired,
    addTag: PropTypes.func.isRequired,
    allTags: PropTypes.array.isRequired,
    clearTags: PropTypes.func.isRequired,
    removeTag: PropTypes.func.isRequired,
    restaurantIds: PropTypes.array.isRequired,
    addedTags: PropTypes.array.isRequired,
    setFlipMove: PropTypes.func.isRequired,
  };

  static defaultProps = {
    exclude: false
  };

  constructor(props) {
    super(props);

    this.state = {
      autosuggestValue: '',
    };

    this.state.shown = !!props.addedTags.length;
  }

  componentDidUpdate(prevProps, prevState) {
    if (this.state.shown !== prevState.shown && this.state.shown) {
      this.autosuggest.input.focus();
    }
    this.props.setFlipMove(true);
  }

  setAutosuggestValue = (event, { newValue, method }) => {
    if (method === 'up' || method === 'down') {
      return;
    }
    this.setState(() => ({
      autosuggestValue: newValue
    }));
  };

  handleSuggestionSelected = (event, { suggestion, method }) => {
    if (method === 'enter') {
      event.preventDefault();
    }
    this.props.setFlipMove(false);
    this.props.addTag(suggestion.id);
    this.setState(() => ({
      autosuggestValue: '',
    }));
  }

  hideForm = () => {
    this.props.clearTags();
    this.props.setFlipMove(false);
    this.setState(() => ({
      autosuggestValue: '',
      shown: false,
    }));
  }

  showForm = () => {
    this.setState(() => ({
      shown: true,
    }));
  }

  removeTagFilter = (tag) => {
    this.props.removeTag(tag);
    this.props.setFlipMove(false);
  }

  render() {
    const {
      addByName,
      addedTags,
      allTags,
      exclude,
      restaurantIds,
    } = this.props;

    const { autosuggestValue, shown } = this.state;

    let form;
    let showButton;

    if (!allTags.length || !restaurantIds.length) {
      return null;
    }

    if (shown) {
      const tags = generateTagList(allTags, addedTags, autosuggestValue);

      form = (
        <form className={s.form} onSubmit={addByName}>
          <Autosuggest
            suggestions={tags}
            focusInputOnSuggestionClick={false}
            getSuggestionValue={getSuggestionValue}
            renderSuggestion={renderSuggestion}
            inputProps={{
              placeholder: exclude ? 'exclude' : 'filter',
              value: autosuggestValue,
              onChange: this.setAutosuggestValue,
            }}
            theme={autosuggestTheme}
            onSuggestionSelected={this.handleSuggestionSelected}
            onSuggestionsFetchRequested={() => {}}
            onSuggestionsClearRequested={() => {}}
            shouldRenderSuggestions={returnTrue}
            ref={a => { this.autosuggest = a; }}
          />
          {addedTags.map(tag => (
            <div
              className={s.tagContainer}
              key={exclude ? `tagExclusion_${tag}` : `tagFilter_${tag}`}
            >
              <TagContainer
                id={tag}
                showDelete
                onDeleteClicked={() => this.removeTagFilter(tag)}
                exclude={exclude}
              />
            </div>
          ))}
          <button
            className="btn btn-default"
            type="button"
            onClick={this.hideForm}
          >
            cancel
          </button>
        </form>
      );
    } else {
      showButton = (
        <button className="btn btn-default" onClick={this.showForm} type="button">
          {exclude ? 'exclude tags' : 'filter by tag'}
        </button>
      );
    }
    return (
      <div className={s.root}>
        {showButton}
        {form}
      </div>
    );
  }
}

export const undecorated = TagFilterForm;
export default withStyles(s)(withStyles(autosuggestTheme)(TagFilterForm));
