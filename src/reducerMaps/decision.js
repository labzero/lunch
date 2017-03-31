import update from 'immutability-helper';
import ActionTypes from '../constants/ActionTypes';
import isFetching from './helpers/isFetching';

export default new Map([
  [ActionTypes.INVALIDATE_DECISION, state =>
    update(state, {
      $merge: {
        didInvalidate: true
      }
    })
  ],
  [ActionTypes.REQUEST_DECISION, state =>
    update(state, {
      $merge: {
        isFetching: true
      }
    })
  ],
  [ActionTypes.RECEIVE_DECISION, (state, action) =>
    update(state, {
      $merge: {
        isFetching: false,
        didInvalidate: false,
        inst: action.inst
      }
    })
  ],
  [ActionTypes.POST_DECISION, isFetching],
  [ActionTypes.DECISION_POSTED, (state, action) =>
    update(state, {
      isFetching: {
        $set: false
      },
      inst: {
        $set: action.decision
      }
    })
  ],
  [ActionTypes.DELETE_DECISION, isFetching],
  [ActionTypes.DECISION_DELETED, (state) =>
    update(state, {
      isFetching: {
        $set: false
      },
      inst: {
        $set: null
      }
    })
  ]
]);
