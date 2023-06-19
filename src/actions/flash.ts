import nodeCrypto from "crypto";
import { Action } from "../interfaces";
import canUseDOM from "../helpers/canUseDOM";

const crypto = canUseDOM ? window.crypto : nodeCrypto;

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
