export const getVoteEntities = state => state.restaurants.items.entities.votes;
export const getVoteById = (state, props) =>
  getVoteEntities(state)[typeof props === 'object' ? props.voteId : props];
