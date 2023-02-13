import { createSelector } from 'reselect';
import dayjs from 'dayjs';

export const getDecisionIds = state => state.decisions.items.result || [];
export const getDecisionEntities = (state) => {
  if (state.decisions.items.entities) {
    return state.decisions.items.entities.decisions;
  }

  return {};
};

export const getDecisionsByDay = createSelector(
  [getDecisionIds, getDecisionEntities],
  (decisionIds, decisionEntities) => decisionIds.reduce((acc, curr) => {
    const decision = decisionEntities[curr];
    const createdAt = dayjs(decision.createdAt);
    let comparisonDate = dayjs().subtract(12, 'hours');
    for (let i = 0; i < 5; i += 1) {
      if (createdAt.isAfter(comparisonDate)) {
        acc[i].push(decision);
        break;
      }
      comparisonDate = comparisonDate.subtract(24, 'hours');
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
  getDecisionIds,
  getDecisionEntities,
  (decisionIds, decisionEntities) => decisionIds.reduce((acc, curr) => {
    const decision = decisionEntities[curr];
    acc[decision.restaurant_id] = new Date(decision.createdAt).toLocaleDateString();
    return acc;
  }, {}),
);

export const areDecisionsLoading = state => state.decisions.didInvalidate;

export const getDecision = createSelector(
  getDecisionIds,
  getDecisionEntities,
  (decisionIds, decisionEntities) => {
    if (decisionIds.length === 0) {
      return undefined;
    }
    const twelveHoursAgo = dayjs().subtract(12, 'hours');
    for (let i = 0; i < decisionIds.length; i += 1) {
      if (dayjs(decisionEntities[decisionIds[i]].createdAt).isAfter(twelveHoursAgo)) {
        return decisionEntities[decisionIds[i]];
      }
    }
    return undefined;
  }
);
