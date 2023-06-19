/* eslint-disable consistent-return */
import { createNextState } from "@reduxjs/toolkit";
import { Reducer, User } from "../interfaces";

const user: Reducer<"user"> = (state, action) =>
  createNextState(state, (draftState) => {
    switch (action.type) {
      case "TEAM_POSTED": {
        if (action.team.roles) {
          action.team.roles.forEach((role) => {
            if (draftState && role.userId === draftState.id) {
              draftState.roles.push(role);
            }
          });
        }
        return;
      }
      case "USER_DELETED": {
        if (draftState && action.isSelf) {
          draftState.roles.splice(
            draftState.roles.map((role) => role.teamId).indexOf(action.team.id),
            1
          );
        }
        return;
      }
      case "USER_PATCHED": {
        if (draftState && action.isSelf) {
          return {
            ...draftState,
            ...action.user,
            roles: draftState.roles.map((role) => {
              if (role.teamId === action.team.id) {
                return {
                  ...role,
                  type: action.user.type,
                };
              }
              return role;
            }),
            type: undefined,
          } as User;
        }
        return;
      }
      case "CURRENT_USER_PATCHED": {
        return action.user;
      }
      default: {
        break;
      }
    }
  });

export default user;
