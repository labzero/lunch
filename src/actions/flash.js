import uuidV1 from 'uuid/v1';
import ActionTypes from '../constants/ActionTypes';

export function flashError(message) {
  return {
    type: ActionTypes.FLASH_ERROR,
    message,
    id: uuidV1()
  };
}

export function flashSuccess(message) {
  return {
    type: ActionTypes.FLASH_SUCCESS,
    message,
    id: uuidV1()
  };
}

export function expireFlash(id) {
  return {
    type: ActionTypes.EXPIRE_FLASH,
    id
  };
}
