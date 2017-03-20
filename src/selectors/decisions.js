export const isDecisionLoading = state =>
  state.decision.didInvalidate && state.decision.isFetching;
export const getDecision = state => state.decision.inst;
