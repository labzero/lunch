import React, { Component, FormEvent, RefObject, createRef } from "react";
import Autosuggest, {
  ChangeEvent,
  SuggestionSelectedEventData,
} from "react-autosuggest";
import withStyles from "isomorphic-style-loader/withStyles";
import Button from "react-bootstrap/Button";
import TagContainer from "../Tag/TagContainer";
import {
  generateTagList,
  getSuggestionValue,
  renderSuggestion,
} from "../../helpers/TagAutosuggestHelper";
import { Tag } from "../../interfaces";
import s from "./TagFilterForm.scss";

// eslint-disable-next-line css-modules/no-unused-class
import autosuggestTheme from "./TagFilterFormAutosuggest.scss";

// eslint-disable-next-line css-modules/no-undef-class
autosuggestTheme.input = "form-control";

const returnTrue = () => true;

export interface TagFilterFormProps {
  exclude?: boolean;
  addByName: (autosuggestValue: string) => (event: FormEvent) => void;
  addTag: (id: number) => void;
  allTags: Tag[];
  clearTags: () => void;
  removeTag: (id: number) => void;
  restaurantIds: number[];
  addedTags: number[];
  setFlipMove: (flip: boolean) => void;
}

interface TagFilterFormState {
  autosuggestValue: string;
  shown: boolean;
}

class TagFilterForm extends Component<TagFilterFormProps, TagFilterFormState> {
  autosuggest: RefObject<Autosuggest>;

  static defaultProps = {
    exclude: false,
  };

  constructor(props: TagFilterFormProps) {
    super(props);

    this.autosuggest = createRef();

    this.state = {
      autosuggestValue: "",
      shown: !!props.addedTags.length,
    };
  }

  componentDidUpdate(
    prevProps: TagFilterFormProps,
    prevState: TagFilterFormState
  ) {
    if (this.state.shown !== prevState.shown && this.state.shown) {
      this.autosuggest.current?.input?.focus();
    }
    this.props.setFlipMove(true);
  }

  setAutosuggestValue = (
    event: FormEvent,
    { newValue, method }: ChangeEvent
  ) => {
    if (method === "up" || method === "down") {
      return;
    }
    this.setState(() => ({
      autosuggestValue: newValue,
    }));
  };

  handleSuggestionSelected = (
    event: FormEvent,
    { suggestion, method }: SuggestionSelectedEventData<Tag>
  ) => {
    if (method === "enter") {
      event.preventDefault();
    }
    this.props.setFlipMove(false);
    this.props.addTag(suggestion.id);
    this.setState(() => ({
      autosuggestValue: "",
    }));
  };

  hideForm = () => {
    this.props.clearTags();
    this.props.setFlipMove(false);
    this.setState(() => ({
      autosuggestValue: "",
      shown: false,
    }));
  };

  showForm = () => {
    this.setState(() => ({
      shown: true,
    }));
  };

  removeTagFilter = (tag: number) => {
    this.props.removeTag(tag);
    this.props.setFlipMove(false);
  };

  render() {
    const { addByName, addedTags, allTags, exclude, restaurantIds } =
      this.props;

    const { autosuggestValue, shown } = this.state;

    let form;
    let showButton;

    if (!allTags.length || !restaurantIds.length) {
      return null;
    }

    if (shown) {
      const tags = generateTagList(allTags, addedTags, autosuggestValue);

      form = (
        <form className={s.form} onSubmit={addByName(autosuggestValue)}>
          <Autosuggest
            suggestions={tags}
            focusInputOnSuggestionClick={false}
            getSuggestionValue={getSuggestionValue}
            renderSuggestion={renderSuggestion}
            inputProps={{
              placeholder: exclude ? "exclude" : "filter",
              value: autosuggestValue,
              onChange: this.setAutosuggestValue,
            }}
            theme={autosuggestTheme}
            onSuggestionSelected={this.handleSuggestionSelected}
            onSuggestionsFetchRequested={() => undefined}
            onSuggestionsClearRequested={() => undefined}
            shouldRenderSuggestions={returnTrue}
            ref={this.autosuggest}
          />
          {addedTags.map((tag) => (
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
          <Button onClick={this.hideForm} variant="light">
            cancel
          </Button>
        </form>
      );
    } else {
      showButton = (
        <Button onClick={this.showForm} variant="light">
          {exclude ? "exclude tags" : "filter by tag"}
        </Button>
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
