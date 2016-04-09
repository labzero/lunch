import ActionTypes from '../constants/ActionTypes';

export function notify(action) {
  return {
    type: ActionTypes.NOTIFY,
    realAction: action
  };
}

export function expireNotification(id) {
  return {
    type: ActionTypes.EXPIRE_NOTIFICATION,
    id
  };
}
