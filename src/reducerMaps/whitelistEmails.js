import update from 'immutability-helper';
import ActionTypes from '../constants/ActionTypes';
import { getWhitelistEmailIds } from '../selectors/whitelistEmails';
import isFetching from './helpers/isFetching';
import setOrMerge from './helpers/setOrMerge';

export default new Map([
  [ActionTypes.DELETE_WHITELIST_EMAIL, isFetching],
  [ActionTypes.WHITELIST_EMAIL_DELETED, (state, action) =>
    update(state, {
      isFetching: {
        $set: false
      },
      items: {
        result: {
          $splice: [[getWhitelistEmailIds({ whitelistEmails: state }).indexOf(action.id), 1]]
        }
      }
    })
  ],
  [ActionTypes.POST_WHITELIST_EMAIL, isFetching],
  [ActionTypes.WHITELIST_EMAIL_POSTED, (state, action) =>
    update(state, {
      items: {
        result: {
          $push: [action.whitelistEmail.id]
        },
        entities: {
          $apply: target =>
            setOrMerge(
              target,
              'whitelistEmails',
              { [action.whitelistEmail.id]: action.whitelistEmail }
            )
        }
      }
    })
  ]
]);
