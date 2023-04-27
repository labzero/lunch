import { Action } from "../interfaces";

export function notify(action: Action): Action {
  return {
    type: "NOTIFY",
    realAction: action
  };
}

export function expireNotification(id: string): Action {
  return {
    type: "EXPIRE_NOTIFICATION",
    id
  };
}
