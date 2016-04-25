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
    if (this.props.tagUi.filterFormShown !== prevProps.tagUi.filterFormShown && this.props.tagUi.filterFormShown) {
      this._autosuggestInput.focus();
    }
  }

  render() {
    let filterForm;
    let showButton;
    if (this.props.tagUi.filterFormShown) {
      const setAutosuggestInput = i => {
        this._autosuggestInput = i;
      };

      filterForm = (
        <form className={s.form} onSubmit={preventDefault}>
          <Autosuggest
            suggestions={this.props.tags}
            focusInputOnSuggestionClick={false}
            getSuggestionValue={getSuggestionValue}
            renderSuggestion={renderSuggestion}
            inputProps={{
              value: this.props.autosuggestValue,
              onChange: this.props.setAutosuggestValue,
              ref: setAutosuggestInput
            }}
            theme={autosuggestTheme}
            onSuggestionSelected={this.props.handleSuggestionSelected}
            shouldRenderSuggestions={returnTrue}
          />
          {this.props.addedTags.map(tag => {
            const boundRemoveTagFilter = this.props.removeTagFilter.bind(undefined, tag);
            return (
              <div className={s.tagContainer} key={`tagFilter_${tag}`}>
                <TagContainer
                  id={tag}
                  showDelete
                  onDeleteClicked={boundRemoveTagFilter}
                />
              </div>
            );
          })}
          <button
            className="btn btn-default"
            type="button"
            onClick={this.props.hideTagFilterForm}
          >
            cancel
          </button>
        </form>
      );
    } else {
      showButton = (
        <button className="btn btn-default" onClick={this.props.showTagFilterForm}>
          {this.props.exclude ? 'exclude tags' : 'filter by tag'}
        </button>
      );
    }
    return (
      <div className={s.root}>{showButton}{filterForm}</div>
    );
  }
}

_TagFilterForm.propTypes = {
  exclude: PropTypes.bool,
  handleSuggestionSelected: PropTypes.func.isRequired,
  removeTagFilter: PropTypes.func.isRequired,
  showTagFilterForm: PropTypes.func.isRequired,
  hideTagFilterForm: PropTypes.func.isRequired,
  autosuggestValue: PropTypes.string.isRequired,
  setAutosuggestValue: PropTypes.func.isRequired,
  addedTags: PropTypes.array.isRequired,
  tags: PropTypes.array.isRequired,
  tagUi: PropTypes.object.isRequired
};

export default withStyles(s)(withStyles(autosuggestTheme)(_TagFilterForm));
