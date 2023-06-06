import { State } from "../interfaces";

export const getMapUi = (state: State) => state.mapUi;
export const getCenter = (state: State) => state.mapUi.center;
