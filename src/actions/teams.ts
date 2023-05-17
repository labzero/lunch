import { ThunkAction } from "@reduxjs/toolkit";
import { processResponse, credentials, jsonHeaders } from "../core/ApiClient";
import { Action, State, Team } from "../interfaces";

export function postTeam(obj: Team): Action {
  return {
    type: "POST_TEAM",
    team: obj,
  };
}

export function teamPosted(obj: Team): Action {
  return {
    type: "TEAM_POSTED",
    team: obj,
  };
}

export function createTeam(
  payload: Team
): ThunkAction<void, State, unknown, Action> {
  return (dispatch) => {
    dispatch(postTeam(payload));
    return fetch("/api/teams", {
      method: "post",
      credentials,
      headers: jsonHeaders,
      body: JSON.stringify(payload),
    })
      .then((response) => processResponse(response, dispatch))
      .then((obj) => dispatch(teamPosted(obj)));
  };
}
