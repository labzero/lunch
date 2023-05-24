import { ListUiItem, State } from "../interfaces";

const blankUi: ListUiItem = {};

export const getListUi = (state: State) => state.listUi;
export const getListUiItemForId = (state: State, restaurantId: number) =>
  getListUi(state)[restaurantId] || blankUi;

export const getNewlyAdded = (state: State) => state.listUi.newlyAdded;
export const getFlipMove = (state: State) => state.listUi.flipMove;
