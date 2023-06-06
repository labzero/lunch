import { ThunkAction } from "@reduxjs/toolkit";
import { Action, State } from "../interfaces";

export function setEditNameFormValue(id: number, value: string): Action {
  return {
    type: "SET_EDIT_NAME_FORM_VALUE",
    id,
    value,
  };
}

export function showEditNameForm(id: number): Action {
  return {
    type: "SHOW_EDIT_NAME_FORM",
    id,
  };
}

export function hideEditNameForm(
  id: number
): ThunkAction<void, State, unknown, Action> {
  return (dispatch) => {
    dispatch(setEditNameFormValue(id, ""));
    dispatch({
      type: "HIDE_EDIT_NAME_FORM",
      id,
    });
  };
}

export function setFlipMove(val: boolean): Action {
  return {
    type: "SET_FLIP_MOVE",
    val,
  };
}
