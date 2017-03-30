export const isDecisionLoading = state =>
  state.decision.didInvalidate;
export const getDecision = state => state.decision.inst;
