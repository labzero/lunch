import { createSelector } from 'reselect';
import moment from 'moment';

export const getDecisionIds = state => state.decisions.items.result;
export const getDecisionEntities = state => state.decisions.items.entities.decisions;

export const getDecisionsByDay = createSelector(
  [getDecisionIds, getDecisionEntities],
  (decisionIds, decisionEntities) => decisionIds.reduce((acc, curr) => {
    const decision = decisionEntities[curr];
    const createdAt = moment(decision.created_at);
    const comparisonDate = moment().subtract(12, 'hours');
    for (let i = 0; i < 5; i += 1) {
      if (createdAt.isAfter(comparisonDate)) {
        acc[i].push(decision);
        break;
      }
      comparisonDate.subtract(24, 'hours');
    }
    return acc;
  }, {
    0: [],
    1: [],
    2: [],
    3: [],
    4: [],
  }),
);

export const getDecisionsByRestaurantId = createSelector(
  getDecisionIds, getDecisionEntities,
  (decisionIds, decisionEntities) => decisionIds.reduce((acc, curr) => {
    const decision = decisionEntities[curr];
    acc[decision.restaurant_id] = new Date(decision.created_at).toLocaleDateString();
    return acc;
  }, {}),
);

export const areDecisionsLoading = state => state.decisions.didInvalidate;

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
);
