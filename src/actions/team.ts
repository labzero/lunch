import { ThunkAction } from "@reduxjs/toolkit";
import { processResponse, jsonHeaders } from "../core/ApiClient";
import { Action, State, Team } from "../interfaces";

export function deleteTeam(): Action {
  return {
    type: "DELETE_TEAM",
  };
}

export function teamDeleted(): Action {
  return {
    type: "TEAM_DELETED",
  };
}

export function removeTeam(): ThunkAction<void, State, unknown, Action> {
  return (dispatch, getState) => {
    const state = getState();
    if (!state.team) {
      return Promise.reject(new Error("No team selected"));
    }
    const teamId = state.team.id;
    const host = state.host;
    dispatch(deleteTeam());
    return fetch(`//${host}/api/teams/${teamId}`, {
      method: "delete",
      credentials: "include",
      headers: jsonHeaders,
    })
      .then((response) => processResponse(response, dispatch))
      .then(() => dispatch(teamDeleted()));
  };
}

export function patchTeam(obj: Partial<Team>): Action {
  return {
    type: "PATCH_TEAM",
    team: obj,
  };
}

export function teamPatched(json: Team): Action {
  return {
    type: "TEAM_PATCHED",
    team: json,
  };
}

export function updateTeam(
  payload: Partial<Team>
): ThunkAction<Promise<Action>, State, unknown, Action> {
  return (dispatch, getState) => {
    const state = getState();
    if (!state.team) {
      return Promise.reject(new Error("No team selected"));
    }
    const teamId = state.team.id;
    const host = state.host;
    dispatch(patchTeam(payload));
    return fetch(`//${host}/api/teams/${teamId}`, {
      method: "PATCH",
      credentials: "include",
      headers: jsonHeaders,
      body: JSON.stringify(payload),
    })
      .then((response) => processResponse(response, dispatch))
      .then((json) => dispatch(teamPatched(json)));
  };
}
