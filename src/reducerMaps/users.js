import { normalize } from 'normalizr';
import update from 'immutability-helper';
import ActionTypes from '../constants/ActionTypes';
import { getUserIds } from '../selectors/users';
import * as schemas from '../schemas';
import isFetching from './helpers/isFetching';

export default new Map([
  [ActionTypes.INVALIDATE_USERS, state =>
    update(state, {
      $merge: {
        didInvalidate: true
      }
    })
  ],
  [ActionTypes.REQUEST_USERS, state =>
    update(state, {
      $merge: {
        isFetching: true
      }
    })
  ],
  [ActionTypes.RECEIVE_USERS, (state, action) =>
    update(state, {
      $merge: {
        isFetching: false,
        didInvalidate: false,
        items: normalize(action.items, [schemas.user]),
        teamSlug: action.teamSlug
      }
    })
  ],
  [ActionTypes.DELETE_USER, isFetching],
  [ActionTypes.USER_DELETED, (state, action) =>
    update(state, {
      isFetching: {
        $set: false
      },
      items: {
        result: {
          $splice: [[getUserIds({ users: state }).indexOf(action.id), 1]]
        }
      }
    })
  ]
]);
