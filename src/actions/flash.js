import ActionTypes from '../constants/ActionTypes';

export function flashError(message) {
  return {
    type: ActionTypes.FLASH_ERROR,
    message
  };
}

export function flashSuccess(message) {
  return {
    type: ActionTypes.FLASH_SUCCESS,
    message
  };
}

export function expireFlash(id) {
  return {
    type: ActionTypes.EXPIRE_FLASH,
    id
  };
}
