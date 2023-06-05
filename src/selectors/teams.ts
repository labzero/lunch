import { createSelector } from "reselect";
import { State } from "../interfaces";

export const getTeamIds = (state: State) => state.teams.items.result;
export const getTeamEntities = (state: State) =>
  state.teams.items.entities.teams;

export const getTeams = createSelector(
  getTeamIds,
  getTeamEntities,
  (teamIds, teamEntities) => teamIds.map((id) => teamEntities[id])
);
