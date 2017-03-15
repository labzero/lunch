import update from 'react-addons-update';
import ActionTypes from '../constants/ActionTypes';
import isFetching from './helpers/isFetching';

export default new Map([
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
