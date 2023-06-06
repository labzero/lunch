import { State } from "../../interfaces";

type StateWithFetching = Extract<State[keyof State], { isFetching: boolean }>;

const isFetching = <T extends StateWithFetching>(state: T) => ({
  ...state,
  isFetching: true,
});

export default isFetching;
