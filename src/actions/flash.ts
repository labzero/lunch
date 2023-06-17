import crypto from "crypto";
import { Action } from "../interfaces";

export function flashError(message: string): Action {
  return {
    type: "FLASH_ERROR",
    message,
    id: crypto.randomUUID(),
  };
}

export function flashSuccess(message: string): Action {
  return {
    type: "FLASH_SUCCESS",
    message,
    id: crypto.randomUUID(),
  };
}

export function expireFlash(id: string): Action {
  return {
    type: "EXPIRE_FLASH",
    id,
  };
}
