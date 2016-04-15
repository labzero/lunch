export const getListUi = state => state.listUi;
export const getListUiItemForId = (state, props) =>
  getListUi(state)[typeof props === 'object' ? props.restaurantId : props] || {};
