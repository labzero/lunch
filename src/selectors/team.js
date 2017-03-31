import { createSelector } from 'reselect';

export const getTeam = state => state.team;

export const getTeamLatLng = createSelector(
  getTeam,
  (team) => ({ lat: team.lat, lng: team.lng })
);
