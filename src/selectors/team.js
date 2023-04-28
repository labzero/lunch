import { createSelector } from 'reselect';

export const getTeam = state => state.team;
export const getTeamDefaultZoom = state => state.team.defaultZoom;
export const getTeamSortDuration = state => state.team.sortDuration;

export const getTeamLatLng = createSelector(
  getTeam,
  team => ({ lat: team.lat, lng: team.lng })
);
