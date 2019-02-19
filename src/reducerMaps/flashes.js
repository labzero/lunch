import ActionTypes from '../constants/ActionTypes';

export default new Map([
  [ActionTypes.FLASH_ERROR, (state, action) => [
    ...state,
    {
      id: action.id,
      message: action.message,
      type: 'error'
    }
  ]
  ],
  [ActionTypes.FLASH_SUCCESS, (state, action) => [
    ...state,
    {
      id: action.id,
      message: action.message,
      type: 'success'
    }
  ]
  ],
  [ActionTypes.EXPIRE_FLASH, (state, action) => state.filter(arr => arr.id !== action.id)
  ]
]);
