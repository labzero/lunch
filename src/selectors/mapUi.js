export const getMapUi = state => state.mapUi;
export const getMarkerSettingsForId = (state, props) =>
  getMapUi(state).markers[typeof props === 'object' ? props.restaurantId : props] || {};
