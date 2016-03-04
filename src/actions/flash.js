import * as ActionTypes from '../ActionTypes';

export function flashError(message) {
  return {
    type: ActionTypes.FLASH_ERROR,
    message
  };
}
