import React, { PropTypes, Component } from 'react';
import Autosuggest from 'react-autosuggest';
import TagContainer from '../../containers/TagContainer';
import { getSuggestionValue, renderSuggestion } from '../../helpers/TagAutosuggestHelper';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './TagFilterForm.scss';
import autosuggestTheme from './TagFilterFormAutosuggest.scss';

autosuggestTheme.input = 'form-control';

const returnTrue = () => true;

const preventDefault = event => event.preventDefault();

export class _TagFilterForm extends Component {
  componentDidUpdate(prevProps) {
    if (this.props.tagUiForm.shown !== prevProps.tagUiForm.shown && this.props.tagUiForm.shown) {
      this._autosuggestInput.focus();
    }
  }

  render() {
    let form;
    let showButton;
    if (this.props.tagUiForm.shown) {
      const setAutosuggestInput = i => {
        this._autosuggestInput = i;
      };

      form = (
        <form className={s.form} onSubmit={preventDefault}>
          <Autosuggest
            suggestions={this.props.tags}
            focusInputOnSuggestionClick={false}
            getSuggestionValue={getSuggestionValue}
            renderSuggestion={renderSuggestion}
            inputProps={{
              placeholder: this.props.exclude ? 'exclude' : 'filter',
              value: this.props.autosuggestValue,
              onChange: this.props.setAutosuggestValue,
              ref: setAutosuggestInput
            }}
            theme={autosuggestTheme}
            onSuggestionSelected={this.props.handleSuggestionSelected}
            shouldRenderSuggestions={returnTrue}
          />
          {this.props.addedTags.map(tag => {
            const boundRemoveTag = this.props.removeTag.bind(undefined, tag);
            return (
              <div className={s.tagContainer} key={this.props.exclude ? `tagExclusion_${tag}` : `tagFilter_${tag}`}>
                <TagContainer
                  id={tag}
                  showDelete
                  onDeleteClicked={boundRemoveTag}
                  exclude={this.props.exclude}
                />
              </div>
            );
          })}
          <button
            className="btn btn-default"
            type="button"
            onClick={this.props.hideForm}
          >
            cancel
          </button>
        </form>
      );
    } else {
      showButton = (
        <button className="btn btn-default" onClick={this.props.showForm}>
          {this.props.exclude ? 'exclude tags' : 'filter by tag'}
        </button>
      );
    }
    return (
      <div className={s.root}>{showButton}{form}</div>
    );
  }
}

_TagFilterForm.propTypes = {
  exclude: PropTypes.bool,
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

export default withStyles(s)(withStyles(autosuggestTheme)(_TagFilterForm));
