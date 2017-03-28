import { createSelector } from 'reselect';

export const getTeamIds = state => state.teams.items.result;
export const getTeamEntities = state => state.teams.items.entities.teams;

export const getTeams = createSelector(
  getTeamIds, getTeamEntities,
  (teamIds, teamEntities) => teamIds.map(id => teamEntities[id])
);
