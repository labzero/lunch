import React, { ChangeEvent, TargetedEvent, useEffect, useRef } from "react";
import withStyles from "isomorphic-style-loader/withStyles";
import Button from "react-bootstrap/Button";
import s from "./RestaurantNameForm.scss";

interface RestaurantNameFormProps {
  editNameFormValue: string;
  setEditNameFormValue: (e: ChangeEvent<HTMLInputElement>) => void;
  changeRestaurantName: (e: TargetedEvent<HTMLFormElement>) => void;
  hideEditNameForm: () => void;
}

const RestaurantNameForm = (props: RestaurantNameFormProps) => {
  const input = useRef<HTMLInputElement>(null);

  useEffect(() => {
    // React Bootstrap steals focus, grab it back
    setTimeout(() => {
      input.current?.focus();
    }, 1);
  }, []);

  return (
    <form onSubmit={props.changeRestaurantName}>
      <span className={s.inputContainer}>
        <input
          type="text"
          className="form-control input-sm"
          value={props.editNameFormValue}
          onChange={props.setEditNameFormValue}
          ref={input}
        />
      </span>
      <Button
        type="submit"
        className={s.button}
        disabled={props.editNameFormValue === ""}
        size="sm"
        variant="primary"
      >
        ok
      </Button>
      <Button
        className={s.button}
        onClick={props.hideEditNameForm}
        size="sm"
        variant="light"
      >
        cancel
      </Button>
    </form>
  );
};

export default withStyles(s)(RestaurantNameForm);
