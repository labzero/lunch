import React, { PropTypes, Component } from 'react';
import Autosuggest from 'react-autosuggest';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import TagContainer from '../Tag/TagContainer';
import { getSuggestionValue, renderSuggestion } from '../../helpers/TagAutosuggestHelper';
import s from './TagFilterForm.scss';

// eslint-disable-next-line css-modules/no-unused-class
import autosuggestTheme from './TagFilterFormAutosuggest.scss';

// eslint-disable-next-line css-modules/no-undef-class
autosuggestTheme.input = 'form-control';

const returnTrue = () => true;

class TagFilterForm extends Component {
  componentDidUpdate(prevProps) {
    if (this.props.tagUiForm.shown !== prevProps.tagUiForm.shown && this.props.tagUiForm.shown) {
      this.autosuggest.input.focus();
    }
  }

  render() {
    const {
      addByName,
      addedTags,
      autosuggestValue,
      exclude,
      handleSuggestionSelected,
      hideForm,
      removeTag,
      setAutosuggestValue,
      showForm,
      tags,
      tagUiForm
    } = this.props;

    let form;
    let showButton;

    if (!tags.length) {
      return null;
    }

    if (tagUiForm.shown) {
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
              onChange: setAutosuggestValue,
            }}
            theme={autosuggestTheme}
            onSuggestionSelected={handleSuggestionSelected}
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
                onDeleteClicked={() => removeTag(tag)}
                exclude={exclude}
              />
            </div>
          ))}
          <button
            className="btn btn-default"
            type="button"
            onClick={hideForm}
          >
            cancel
          </button>
        </form>
      );
    } else {
      showButton = (
        <button className="btn btn-default" onClick={showForm}>
          {exclude ? 'exclude tags' : 'filter by tag'}
        </button>
      );
    }
    return (
      <div className={s.root}>{showButton}{form}</div>
    );
  }
}

TagFilterForm.propTypes = {
  exclude: PropTypes.bool,
  addByName: PropTypes.func.isRequired,
  handleSuggestionSelected: PropTypes.func.isRequired,
  removeTag: PropTypes.func.isRequired,
  showForm: PropTypes.func.isRequired,
  hideForm: PropTypes.func.isRequired,
  autosuggestValue: PropTypes.string.isRequired,
  setAutosuggestValue: PropTypes.func.isRequired,
  addedTags: PropTypes.array.isRequired,
  tags: PropTypes.array.isRequired,
  tagUiForm: PropTypes.object.isRequired
};

TagFilterForm.defaultProps = {
  exclude: false
};

export const undecorated = TagFilterForm;
export default withStyles(s)(withStyles(autosuggestTheme)(TagFilterForm));
