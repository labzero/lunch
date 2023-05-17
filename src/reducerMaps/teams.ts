import update from "immutability-helper";
import { Reducer } from "../interfaces";
import isFetching from "./helpers/isFetching";

const teams: Reducer<"teams"> = (state, action) => {
  switch (action.type) {
    case "POST_TEAM": {
      return isFetching(state);
    }
    case "TEAM_POSTED": {
      return update(state, {
        isFetching: {
          $set: false,
        },
        items: {
          result: {
            $push: [action.team.id],
          },
          entities: {
            teams: state.items.entities.teams
              ? {
                  $merge: {
                    [action.team.id]: action.team,
                  },
                }
              : {
                  $set: {
                    [action.team.id]: action.team,
                  },
                },
          },
        },
      });
    }
    case "USER_DELETED": {
      if (action.isSelf) {
        return update(state, {
          items: {
            result: {
              $splice: [[state.items.result.indexOf(action.team.id), 1]],
            },
          },
        });
      }
      return state;
    }
  }
  return state;
};

export default teams;
