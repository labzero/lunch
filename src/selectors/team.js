import { createSelector } from 'reselect';

export const getTeam = state => state.team;
export const getTeamDefaultZoom = state => state.team.default_zoom;

export const getTeamLatLng = createSelector(
  getTeam,
  team => ({ lat: team.lat, lng: team.lng })
);
