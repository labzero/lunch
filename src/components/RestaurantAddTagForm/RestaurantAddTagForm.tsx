import React, { Component, RefObject, TargetedEvent, createRef } from "react";
import Autosuggest, {
  ChangeEvent,
  SuggestionSelectedEventData,
} from "react-autosuggest";
import Button from "react-bootstrap/Button";
import withStyles from "isomorphic-style-loader/withStyles";
import {
  generateTagList,
  getSuggestionValue,
  renderSuggestion,
} from "../../helpers/TagAutosuggestHelper";
import { Tag } from "../../interfaces";
import s from "./RestaurantAddTagForm.scss";

// eslint-disable-next-line css-modules/no-unused-class
import autosuggestTheme from "./RestaurantAddTagFormAutosuggest.scss";

const returnTrue = () => true;

// eslint-disable-next-line css-modules/no-undef-class
autosuggestTheme.input = "form-control input-sm";

export interface RestaurantAddTagFormProps {
  addedTags: number[];
  addNewTagToRestaurant: (tag: string) => void;
  addTagToRestaurant: (tag: number) => void;
  hideAddTagForm: () => void;
  tags: Tag[];
}

interface RestaurantAddFormState {
  autosuggestValue: string;
}

export class _RestaurantAddTagForm extends Component<
  RestaurantAddTagFormProps,
  RestaurantAddFormState
> {
  declare autosuggest: RefObject<Autosuggest>;

  constructor(props: RestaurantAddTagFormProps) {
    super(props);

    this.autosuggest = createRef();

    this.state = {
      autosuggestValue: "",
    };
  }

  componentDidMount() {
    this.autosuggest.current?.input?.focus();
  }

  setAddTagAutosuggestValue = (
    event: TargetedEvent,
    { newValue, method }: ChangeEvent
  ) => {
    if (method === "up" || method === "down") {
      return;
    }
    this.setState(() => ({
      autosuggestValue: newValue,
    }));
  };

  handleSubmit = (event: TargetedEvent) => {
    event.preventDefault();
    this.props.addNewTagToRestaurant(this.state.autosuggestValue);
    this.setState(() => ({
      autosuggestValue: "",
    }));
  };

  handleSuggestionSelected = (
    event: TargetedEvent,
    { suggestion, method }: SuggestionSelectedEventData<Tag>
  ) => {
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
          ref={this.autosuggest}
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
