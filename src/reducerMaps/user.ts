import update from "immutability-helper";
import { Reducer, User } from "../interfaces";

const user: Reducer<"user"> = (state, action) => {
  switch (action.type) {
    case "TEAM_POSTED": {
      let newState: typeof state | undefined;
      if (action.team.roles) {
        action.team.roles.forEach((role) => {
          if (role.userId === state.id) {
            newState = update(newState || state, {
              roles: {
                $push: [role],
              },
            });
          }
        });
      }

      return newState || state;
    }
    case "USER_DELETED": {
      if (action.isSelf) {
        return update(state, {
          roles: {
            $splice: [
              [
                state.roles.map((role) => role.teamId).indexOf(action.team.id),
                1,
              ],
            ],
          },
        });
      }
      return state;
    }
    case "USER_PATCHED": {
      if (action.isSelf) {
        return {
          ...state,
          ...action.user,
          roles: state.roles.map((role) => {
            if (role.teamId === action.team.id) {
              return {
                ...role,
                type: action.user.type!,
              };
            }
            return role;
          }),
          type: undefined,
        };
      }
      return state;
    }
    case "CURRENT_USER_PATCHED": {
      return action.user;
    }
  }
  return state;
};

export default user;
