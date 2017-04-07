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
  [ActionTypes.FLASH_SUCCESS, (state, action) =>
    [
      ...state,
      {
        message: action.message,
        type: 'success'
      }
    ]
  ],
  [ActionTypes.EXPIRE_FLASH, (state, action) => {
    const newState = Array.from(state);
    newState.splice(action.id, 1);
    return newState;
  }]
]);
