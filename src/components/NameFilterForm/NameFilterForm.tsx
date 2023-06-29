import React, { ChangeEvent, Component, RefObject, createRef } from "react";
import withStyles from "isomorphic-style-loader/withStyles";
import Button from "react-bootstrap/Button";
import s from "./NameFilterForm.scss";

interface NameFilterFormProps {
  nameFilter: string;
  restaurantIds: string[];
  setFlipMove: (value: boolean) => void;
  setNameFilter: (value: string) => void;
}

interface NameFilterFormState {
  shown: boolean;
}

class NameFilterForm extends Component<
  NameFilterFormProps,
  NameFilterFormState
> {
  declare input: RefObject<HTMLInputElement>;

  constructor(props: NameFilterFormProps) {
    super(props);

    this.input = createRef();

    if (props.nameFilter.length) {
      this.state = {
        shown: true,
      };
    } else {
      this.state = {
        shown: false,
      };
    }
  }

  componentDidUpdate(
    prevProps: NameFilterFormProps,
    prevState: NameFilterFormState
  ) {
    if (this.state.shown !== prevState.shown) {
      if (this.state.shown) {
        this.input.current?.focus();
      } else {
        this.setFlipMoveTrue();
      }
    }
  }

  setFlipMoveFalse = () => {
    this.props.setFlipMove(false);
  };

  setFlipMoveTrue = () => {
    this.props.setFlipMove(true);
  };

  setNameFilterValue = (event: ChangeEvent<HTMLInputElement>) => {
    this.props.setNameFilter(event.currentTarget.value);
  };

  hideForm = () => {
    this.props.setFlipMove(false);
    this.props.setNameFilter("");
    this.setState(() => ({
      shown: false,
    }));
  };

  showForm = () => {
    this.setState(() => ({
      shown: true,
    }));
  };

  render() {
    const { nameFilter, restaurantIds } = this.props;

    const { shown } = this.state;

    let child;

    if (!restaurantIds.length) {
      return null;
    }

    if (shown) {
      child = (
        <form className={s.form}>
          <div className={s.container}>
            <input
              className={`${s.input} form-control`}
              placeholder="filter"
              value={nameFilter}
              onChange={this.setNameFilterValue}
              onFocus={this.setFlipMoveFalse}
              onBlur={this.setFlipMoveTrue}
              ref={this.input}
            />
          </div>
          <Button onClick={this.hideForm} variant="light">
            cancel
          </Button>
        </form>
      );
    } else {
      child = (
        <Button onClick={this.showForm} variant="light">
          filter by name
        </Button>
      );
    }
    return <div className={s.root}>{child}</div>;
  }
}

export const undecorated = NameFilterForm;
export default withStyles(s)(NameFilterForm);
