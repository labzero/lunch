import { State } from "../interfaces";

export const getVoteEntities = (state: State) =>
  state.restaurants.items.entities.votes;
export const getVoteById = (state: State, props: { voteId: number } | number) =>
  getVoteEntities(state)?.[typeof props === "object" ? props.voteId : props];
