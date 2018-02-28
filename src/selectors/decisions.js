import { createSelector } from 'reselect';
import moment from 'moment';

export const getDecisionIds = state => state.decisions.items.result;
export const getDecisionEntities = state => state.decisions.items.entities.decisions;

export const areDecisionsLoading = state =>
  state.decisions.didInvalidate;

export const getDecision = createSelector(
  getDecisionIds, getDecisionEntities,
  (decisionIds, decisionEntities) => {
    if (decisionIds.length === 0) {
      return undefined;
    }
    const twelveHoursAgo = moment().subtract(12, 'hours');
    for (let i = 0; i < decisionIds.length; i += 1) {
      if (moment(decisionEntities[decisionIds[i]].created_at).isAfter(twelveHoursAgo)) {
        return decisionEntities[decisionIds[i]];
      }
    }
    return undefined;
  }
)
