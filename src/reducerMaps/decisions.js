import update from 'immutability-helper';
import { normalize } from 'normalizr';
import ActionTypes from '../constants/ActionTypes';
import * as schemas from '../schemas';
import isFetching from './helpers/isFetching';

export default new Map([
  [ActionTypes.INVALIDATE_DECISIONS, state => update(state, {
    $merge: {
      didInvalidate: true
    }
  })
  ],
  [ActionTypes.REQUEST_DECISIONS, isFetching],
  [ActionTypes.RECEIVE_DECISIONS, (state, action) => update(state, {
    $merge: {
      isFetching: false,
      didInvalidate: false,
      items: normalize(action.items, [schemas.decision])
    }
  })
  ],
  [ActionTypes.POST_DECISION, isFetching],
  [ActionTypes.DECISION_POSTED, (state, action) => update(state, {
    isFetching: {
      $set: false
    },
    items: {
      entities: {
        decisions: state.items.entities.decisions ? {
          $merge: {
            [action.decision.id]: action.decision
          }
        } : {
          $set: {
            [action.decision.id]: action.decision
          }
        }
      },
      result: {
        $apply: result => {
          const deselectedIds = action.deselected.map(d => d.id);
          return result.reduce((acc, curr) => {
            if (deselectedIds.indexOf(curr) === -1) {
              acc.push(curr);
            }
            return acc;
          }, [action.decision.id]);
        },
      },
    }
  })
  ],
  [ActionTypes.DELETE_DECISION, isFetching],
  [ActionTypes.DECISIONS_DELETED, (state, action) => {
    const decisionIds = action.decisions.map(d => d.id);
    const newState = {
      isFetching: {
        $set: false
      },
      items: {
        result: {
          $apply: result => result.filter(id => decisionIds.indexOf(id) === -1),
        },
      },
    };
    return update(state, newState);
  }]
]);
