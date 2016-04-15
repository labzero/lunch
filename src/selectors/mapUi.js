export const getMapUi = state => state.mapUi;
export const getMarkerSettingsForId = (state, id) => getMapUi(state).markers[id] || {};
