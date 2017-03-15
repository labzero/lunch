import update from 'immutability-helper';
import ActionTypes from '../constants/ActionTypes';

export default new Map([
  [ActionTypes.SET_EMAIL_WHITELIST_INPUT_VALUE, (state, action) =>
    update(state, {
      inputValue: {
        $set: action.value
      }
    })
  ],
  [ActionTypes.WHITELIST_EMAIL_POSTED, state =>
    update(state, {
      inputValue: {
        $set: ''
      }
    })
  ]
]);
