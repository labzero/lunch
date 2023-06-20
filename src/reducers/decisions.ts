import { createNextState } from "@reduxjs/toolkit";
import { normalize } from "normalizr";
import { Reducer } from "../interfaces";
import * as schemas from "../schemas";

const decisions: Reducer<"decisions"> = (state, action) =>
  createNextState(state, (draftState) => {
    switch (action.type) {
      case "INVALIDATE_DECISIONS": {
        draftState.didInvalidate = true;
        return;
      }
      case "REQUEST_DECISIONS":
      case "POST_DECISION":
      case "DELETE_DECISION": {
        draftState.isFetching = true;
        return;
      }
      case "RECEIVE_DECISIONS": {
        draftState.isFetching = false;
        draftState.didInvalidate = false;
        draftState.items = normalize(action.items, [schemas.decision]);
        return;
      }
      case "DECISION_POSTED": {
        draftState.isFetching = false;
        draftState.items.entities.decisions = {
          ...draftState.items.entities.decisions,
          [action.decision.id]: action.decision,
        };
        const deselectedIds = action.deselected.map((d) => d.id);
        draftState.items.result = draftState.items.result.reduce(
          (acc, curr) => {
            if (deselectedIds.indexOf(curr) === -1) {
              acc.push(curr);
            }
            return acc;
          },
          [action.decision.id]
        );
        return;
      }
      case "DECISIONS_DELETED": {
        const decisionIds = action.decisions.map((d) => d.id);
        draftState.isFetching = false;
        draftState.items.result = draftState.items.result.filter(
          (id) => decisionIds.indexOf(id) === -1
        );
        break;
      }
      default:
        break;
    }
  });

export default decisions;
