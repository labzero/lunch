import { normalize } from "normalizr";
import { createNextState } from "@reduxjs/toolkit";
import { getTagIds, getTagById } from "../selectors/tags";
import * as schemas from "../schemas";
import { Reducer } from "../interfaces";
import maybeAddToString from "../helpers/maybeAddToString";

const tags: Reducer<"tags"> = (state, action) =>
  createNextState(state, (draftState) => {
    switch (action.type) {
      case "INVALIDATE_TAGS": {
        draftState.didInvalidate = true;
        return;
      }
      case "REQUEST_TAGS":
      case "DELETE_TAG": {
        draftState.isFetching = true;
        return;
      }
      case "RECEIVE_TAGS": {
        draftState.isFetching = false;
        draftState.didInvalidate = false;
        draftState.items = normalize(action.items, [schemas.tag]);
        return;
      }
      case "POSTED_TAG_TO_RESTAURANT": {
        draftState.items.entities.tags[action.id].restaurant_count =
          maybeAddToString(
            getTagById({ tags: draftState }, action.id).restaurant_count,
            1
          );
        return;
      }
      case "POSTED_NEW_TAG_TO_RESTAURANT": {
        draftState.items.result.push(action.tag.id);
        draftState.items.entities.tags = {
          ...draftState.items.entities.tags,
          [action.tag.id]: action.tag,
        };
        return;
      }
      case "DELETED_TAG_FROM_RESTAURANT": {
        draftState.isFetching = false;
        draftState.items.entities.tags[action.id].restaurant_count =
          maybeAddToString(
            state.items.entities.tags[action.id].restaurant_count,
            -1
          );
        return;
      }
      case "TAG_DELETED": {
        draftState.isFetching = false;
        const tagIndex = getTagIds({ tags: draftState }).indexOf(action.id);
        if (tagIndex !== -1) {
          draftState.items.result.splice(tagIndex, 1);
        }
        break;
      }
      default:
        break;
    }
  });

export default tags;
