import { normalize } from "normalizr";
import { createNextState } from "@reduxjs/toolkit";
import { getUserIds } from "../selectors/users";
import * as schemas from "../schemas";
import { Reducer, State } from "../interfaces";

const users: Reducer<"users"> = (state, action) =>
  createNextState(state, (draftState) => {
    switch (action.type) {
      case "INVALIDATE_USERS": {
        draftState.didInvalidate = true;
        return;
      }
      case "REQUEST_USERS":
      case "DELETE_USER":
      case "POST_USER":
      case "PATCH_USER": {
        draftState.isFetching = true;
        return;
      }
      case "RECEIVE_USERS": {
        draftState.isFetching = false;
        draftState.didInvalidate = false;
        draftState.items = normalize(action.items, [schemas.user]);
        return;
      }
      case "USER_DELETED": {
        draftState.isFetching = false;
        draftState.items.result.splice(
          getUserIds({ users: draftState } as State).indexOf(action.id),
          1
        );
        return;
      }
      case "USER_POSTED": {
        draftState.items.result.push(action.user.id);
        draftState.items.entities.users = {
          ...draftState.items.entities.users,
          [action.user.id]: action.user,
        };
        return;
      }
      case "USER_PATCHED": {
        draftState.isFetching = false;
        draftState.items.entities.users[action.id] = {
          ...draftState.items.entities.users[action.id],
          ...action.user,
        };
        break;
      }
      default:
        break;
    }
  });

export default users;
