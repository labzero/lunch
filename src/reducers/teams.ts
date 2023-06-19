import { createNextState } from "@reduxjs/toolkit";
import { Reducer } from "../interfaces";

const teams: Reducer<"teams"> = (state, action) =>
  createNextState(state, (draftState) => {
    switch (action.type) {
      case "POST_TEAM": {
        draftState.isFetching = true;
        return;
      }
      case "TEAM_POSTED": {
        draftState.isFetching = false;
        draftState.items.result.push(action.team.id);
        draftState.items.entities.teams = {
          ...draftState.items.entities.teams,
          [action.team.id]: action.team,
        };
        return;
      }
      case "USER_DELETED": {
        if (action.isSelf) {
          draftState.items.result.splice(
            state.items.result.indexOf(action.team.id),
            1
          );
        }
        break;
      }
      default:
        break;
    }
  });

export default teams;
