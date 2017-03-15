import ActionTypes from '../constants/ActionTypes';

export default new Map([
  [ActionTypes.FLASH_ERROR, (state, action) =>
    [
      ...state,
      {
        message: action.message,
        type: 'error'
      }
    ]
  ],
  [ActionTypes.EXPIRE_FLASH, (state, action) =>
    Array.from(state).splice(action.id, 1)
  ]
]);
