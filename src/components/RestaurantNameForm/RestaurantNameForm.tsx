import React, {
  ChangeEvent,
  Component,
  FormEvent,
  RefObject,
  createRef,
} from "react";
import withStyles from "isomorphic-style-loader/withStyles";
import Button from "react-bootstrap/Button";
import s from "./RestaurantNameForm.scss";

interface RestaurantNameFormProps {
  editNameFormValue: string;
  setEditNameFormValue: (e: ChangeEvent<HTMLInputElement>) => void;
  changeRestaurantName: (e: FormEvent<HTMLFormElement>) => void;
  hideEditNameForm: () => void;
}

class RestaurantNameForm extends Component<RestaurantNameFormProps> {
  input: RefObject<HTMLInputElement>;

  componentDidMount() {
    // React Bootstrap steals focus, grab it back
    this.input = createRef<HTMLInputElement>();
    setTimeout(() => {
      this.input.current?.focus();
    }, 1);
  }

  render() {
    return (
      <form onSubmit={this.props.changeRestaurantName}>
        <span className={s.inputContainer}>
          <input
            type="text"
            className="form-control input-sm"
            value={this.props.editNameFormValue}
            onChange={this.props.setEditNameFormValue}
            ref={this.input}
          />
        </span>
        <Button
          type="submit"
          className={s.button}
          disabled={this.props.editNameFormValue === ""}
          size="sm"
          variant="primary"
        >
          ok
        </Button>
        <Button
          className={s.button}
          onClick={this.props.hideEditNameForm}
          size="sm"
          variant="light"
        >
          cancel
        </Button>
      </form>
    );
  }
}

export default withStyles(s)(RestaurantNameForm);
