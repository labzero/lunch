import update from "immutability-helper";
import { normalize } from "normalizr";
import { Reducer } from "../interfaces";
import * as schemas from "../schemas";
import isFetching from "./helpers/isFetching";

const decisions: Reducer<"decisions"> = (state, action) => {
  switch (action.type) {
    case "INVALIDATE_DECISIONS": {
      return update(state, {
        $merge: {
          didInvalidate: true,
        },
      });
    }
    case "REQUEST_DECISIONS":
    case "POST_DECISION":
    case "DELETE_DECISION": {
      return isFetching(state);
    }
    case "RECEIVE_DECISIONS": {
      return update(state, {
        $merge: {
          isFetching: false,
          didInvalidate: false,
          items: normalize(action.items, [schemas.decision]),
        },
      });
    }
    case "DECISION_POSTED": {
      return update(state, {
        isFetching: {
          $set: false,
        },
        items: {
          entities: {
            decisions: state.items.entities.decisions
              ? {
                  $merge: {
                    [action.decision.id]: action.decision,
                  },
                }
              : {
                  $set: {
                    [action.decision.id]: action.decision,
                  },
                },
          },
          result: {
            $apply: (result: number[]) => {
              const deselectedIds = action.deselected.map((d) => d.id);
              return result.reduce(
                (acc, curr) => {
                  if (deselectedIds.indexOf(curr) === -1) {
                    acc.push(curr);
                  }
                  return acc;
                },
                [action.decision.id]
              );
            },
          },
        },
      });
    }
    case "DECISIONS_DELETED": {
      const decisionIds = action.decisions.map((d) => d.id);
      const newState = {
        isFetching: {
          $set: false,
        },
        items: {
          result: {
            $apply: (result: number[]) =>
              result.filter((id) => decisionIds.indexOf(id) === -1),
          },
        },
      };
      return update(state, newState);
    }
  }
  return state;
};

export default decisions;
