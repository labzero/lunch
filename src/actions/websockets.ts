import { ThunkAction } from "@reduxjs/toolkit";
import { sortRestaurants } from "./restaurants";
import { notify } from "./notifications";
import { Action, Dispatch, State } from "../interfaces";

let sortTimeout: NodeJS.Timer;

const sort = (dispatch: Dispatch) => {
  clearTimeout(sortTimeout);
  sortTimeout = setTimeout(() => {
    dispatch(sortRestaurants());
  }, 1000);
};

const dispatchNotify: (
  data: Action
) => ThunkAction<void, State, unknown, Action> = (data) => (dispatch) => {
  dispatch(notify(data));
  dispatch(data);
};

const notifyDispatch: (
  data: Action
) => ThunkAction<void, State, unknown, Action> = (data) => (dispatch) => {
  dispatch(notify(data));
  dispatch(data);
};

const dispatchSortNotify: (
  data: Action
) => ThunkAction<void, State, unknown, Action> = (data) => (dispatch) => {
  dispatch(data);
  sort(dispatch);
  dispatch(notify(data));
};

const notifyDispatchSort: (
  data: Action
) => ThunkAction<void, State, unknown, Action> = (data) => (dispatch) => {
  dispatch(notify(data));
  dispatch(data);
  sort(dispatch);
};

const actionMap: Partial<{
  [key in Action["type"]]: (
    data: Action
  ) => ThunkAction<void, State, unknown, Action>;
}> = {
  RESTAURANT_POSTED: dispatchSortNotify,
  RESTAURANT_DELETED: notifyDispatch,
  RESTAURANT_RENAMED: notifyDispatchSort,
  VOTE_POSTED: notifyDispatchSort,
  VOTE_DELETED: notifyDispatchSort,
  POSTED_TAG_TO_RESTAURANT: dispatchNotify,
  POSTED_NEW_TAG_TO_RESTAURANT: dispatchNotify,
  DELETED_TAG_FROM_RESTAURANT: dispatchNotify,
  TAG_DELETED: notifyDispatch,
  DECISION_POSTED: dispatchSortNotify,
  DECISIONS_DELETED: dispatchSortNotify,
};

export function messageReceived(
  payload: string
): ThunkAction<void, State, unknown, Action> {
  return (dispatch) => {
    try {
      const data = JSON.parse(payload) as Action;
      const action = actionMap[data.type];
      if (action === undefined) {
        dispatch(data);
      } else {
        dispatch(action(data));
      }
    } catch (SyntaxError) {
      // console.error('Couldn\'t parse message data.');
    }
  };
}
