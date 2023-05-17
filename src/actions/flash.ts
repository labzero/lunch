import { v1 } from "uuid";
import { Action } from "../interfaces";

export function flashError(message: string): Action {
  return {
    type: "FLASH_ERROR",
    message,
    id: v1(),
  };
}

export function flashSuccess(message: string): Action {
  return {
    type: "FLASH_SUCCESS",
    message,
    id: v1(),
  };
}

export function expireFlash(id: string): Action {
  return {
    type: "EXPIRE_FLASH",
    id,
  };
}
