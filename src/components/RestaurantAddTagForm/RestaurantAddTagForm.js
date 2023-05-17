import PropTypes from "prop-types";
import React, { Component } from "react";
import Autosuggest from "react-autosuggest";
import Button from "react-bootstrap/Button";
import withStyles from "isomorphic-style-loader/withStyles";
import {
  generateTagList,
  getSuggestionValue,
  renderSuggestion,
} from "../../helpers/TagAutosuggestHelper";
import s from "./RestaurantAddTagForm.scss";

// eslint-disable-next-line css-modules/no-unused-class
import autosuggestTheme from "./RestaurantAddTagFormAutosuggest.scss";

const returnTrue = () => true;

// eslint-disable-next-line css-modules/no-undef-class
autosuggestTheme.input = "form-control input-sm";

export class _RestaurantAddTagForm extends Component {
  static propTypes = {
    addedTags: PropTypes.array.isRequired,
    addNewTagToRestaurant: PropTypes.func.isRequired,
    addTagToRestaurant: PropTypes.func.isRequired,
    hideAddTagForm: PropTypes.func.isRequired,
    tags: PropTypes.array.isRequired,
  };

  constructor(props) {
    super(props);

    this.state = {
      autosuggestValue: "",
    };
  }

  componentDidMount() {
    this.autosuggest.input.focus();
  }

  setAddTagAutosuggestValue = (event, { newValue, method }) => {
    if (method === "up" || method === "down") {
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
      autosuggestValue: "",
    }));
  };

  handleSuggestionSelected = (event, { suggestion, method }) => {
    if (method === "enter") {
      event.preventDefault();
    }
    this.props.addTagToRestaurant(suggestion.id);
    this.setState(() => ({
      autosuggestValue: "",
    }));
  };

  render() {
    const { addedTags, hideAddTagForm, tags } = this.props;

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
          onSuggestionsFetchRequested={() => undefined}
          onSuggestionsClearRequested={() => undefined}
          shouldRenderSuggestions={returnTrue}
          ref={(a) => {
            this.autosuggest = a;
          }}
        />
        <Button
          className={s.button}
          type="submit"
          disabled={autosuggestValue === ""}
          size="sm"
          variant="primary"
        >
          add
        </Button>
        <Button
          className={s.button}
          onClick={hideAddTagForm}
          size="sm"
          variant="light"
        >
          done
        </Button>
      </form>
    );
  }
}

export default withStyles(s, autosuggestTheme)(_RestaurantAddTagForm);
