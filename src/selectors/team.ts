import { createSelector } from "reselect";
import { State } from "../interfaces";

export const getTeam = (state: State) => state.team;
export const getTeamDefaultZoom = (state: State) => state.team?.defaultZoom;
export const getTeamSortDuration = (state: State) => state.team?.sortDuration;

export const getTeamLatLng = createSelector(getTeam, (team) => ({
  lat: team!.lat,
  lng: team!.lng,
}));
