import { normalize } from "normalizr";
import update from "immutability-helper";
import { getTagIds, getTagById } from "../selectors/tags";
import * as schemas from "../schemas";
import isFetching from "./helpers/isFetching";
import { Reducer } from "../interfaces";
import maybeAddToString from "../helpers/maybeAddToString";

const tags: Reducer<"tags"> = (state, action) => {
  switch (action.type) {
    case "INVALIDATE_TAGS": {
      return update(state, {
        $merge: {
          didInvalidate: true,
        },
      });
    }
    case "REQUEST_TAGS": {
      return update(state, {
        $merge: {
          isFetching: true,
        },
      });
    }
    case "RECEIVE_TAGS": {
      return update(state, {
        $merge: {
          isFetching: false,
          didInvalidate: false,
          items: normalize(action.items, [schemas.tag]),
        },
      });
    }
    case "POSTED_TAG_TO_RESTAURANT": {
      return update(state, {
        items: {
          entities: {
            tags: {
              [action.id]: {
                restaurant_count: {
                  $set: maybeAddToString(
                    getTagById({ tags: state }, action.id).restaurant_count,
                    1
                  ),
                },
              },
            },
          },
        },
      });
    }
    case "POSTED_NEW_TAG_TO_RESTAURANT": {
      return update(state, {
        items: {
          result: {
            $push: [action.tag.id],
          },
          entities: {
            tags: state.items.entities.tags
              ? {
                  $merge: {
                    [action.tag.id]: action.tag,
                  },
                }
              : {
                  $set: {
                    [action.tag.id]: action.tag,
                  },
                },
          },
        },
      });
    }
    case "DELETED_TAG_FROM_RESTAURANT": {
      return update(state, {
        isFetching: {
          $set: false,
        },
        items: {
          entities: {
            tags: {
              [action.id]: {
                $merge: {
                  restaurant_count: maybeAddToString(
                    state.items.entities.tags[action.id].restaurant_count,
                    -1
                  ),
                },
              },
            },
          },
        },
      });
    }
    case "DELETE_TAG": {
      return isFetching(state);
    }
    case "TAG_DELETED": {
      const tagIndex = getTagIds({ tags: state }).indexOf(action.id);
      return update(state, {
        isFetching: {
          $set: false,
        },
        items: {
          $apply: (items) => {
            if (tagIndex !== -1) {
              const result = [...items.result];
              result.splice(tagIndex, 1);
              return {
                ...items,
                result,
              };
            }
            return items;
          },
        },
      });
    }
  }
  return state;
};

export default tags;
