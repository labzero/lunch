import { createSelector } from 'reselect';

export const getTeamSlug = (state, props) => typeof props === 'object' ? props.teamSlug : props;

export const getTeamIds = state => state.teams.items.result;
export const getTeamEntities = state => state.teams.items.entities.teams;

export const getTeams = createSelector(
  getTeamIds, getTeamEntities,
  (teamIds, teamEntities) => teamIds.map(id => teamEntities[id])
);

export const getTeamById = (state, props) =>
  getTeamEntities(state)[typeof props === 'object' ? props.teamId : props];

export const getTeamBySlug = createSelector(
  getTeams, getTeamSlug,
  (teams, teamSlug) => teams.find(team => team.slug === teamSlug)
);
