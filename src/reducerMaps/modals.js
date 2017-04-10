import update from 'immutability-helper';
import ActionTypes from '../constants/ActionTypes';
import setOrMerge from './helpers/setOrMerge';

export default new Map([
  [ActionTypes.SHOW_MODAL, (state, action) =>
    update(state, {
      $merge: {
        [action.name]: {
          shown: true,
          ...action.opts
        }
      }
    })
  ],
  [ActionTypes.HIDE_MODAL, (state, action) =>
    update(state, {
      $apply: target => setOrMerge(target, action.name, { shown: false })
    })
  ]
]);
