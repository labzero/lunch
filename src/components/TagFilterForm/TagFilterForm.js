import React, { PropTypes, Component } from 'react';
import Autosuggest from 'react-autosuggest';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import TagContainer from '../../containers/TagContainer';
import { getSuggestionValue, renderSuggestion } from '../../helpers/TagAutosuggestHelper';
import s from './TagFilterForm.scss';
import autosuggestTheme from './TagFilterFormAutosuggest.scss';

autosuggestTheme.input = 'form-control';

const returnTrue = () => true;

class TagFilterForm extends Component {
  componentDidUpdate(prevProps) {
    if (this.props.tagUiForm.shown !== prevProps.tagUiForm.shown && this.props.tagUiForm.shown) {
      this.autosuggest.input.focus();
    }
  }

  render() {
    let form;
    let showButton;
    if (this.props.tagUiForm.shown) {
      form = (
        <form className={s.form} onSubmit={this.props.addByName}>
          <Autosuggest
            suggestions={this.props.tags}
            focusInputOnSuggestionClick={false}
            getSuggestionValue={getSuggestionValue}
            renderSuggestion={renderSuggestion}
            inputProps={{
              placeholder: this.props.exclude ? 'exclude' : 'filter',
              value: this.props.autosuggestValue,
              onChange: this.props.setAutosuggestValue,
            }}
            theme={autosuggestTheme}
            onSuggestionSelected={this.props.handleSuggestionSelected}
            shouldRenderSuggestions={returnTrue}
            ref={a => { this.autosuggest = a; }}
          />
          {this.props.addedTags.map(tag => (
            <div
              className={s.tagContainer}
              key={this.props.exclude ? `tagExclusion_${tag}` : `tagFilter_${tag}`}
            >
              <TagContainer
                id={tag}
                showDelete
                onDeleteClicked={() => this.props.removeTag(tag)}
                exclude={this.props.exclude}
              />
            </div>
          ))}
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

export const undecorated = TagFilterForm;
export default withStyles(s)(withStyles(autosuggestTheme)(TagFilterForm));
