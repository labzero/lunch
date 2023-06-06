import { Action, ConfirmOpts, PastDecisionsOpts } from "../interfaces";

export function showModal(name: string): Action;
export function showModal(
  name: "pastDecisions",
  opts?: PastDecisionsOpts
): Action;
export function showModal(name: "confirm", opts?: ConfirmOpts): Action;

export function showModal(name: unknown, opts?: unknown): unknown {
  return {
    type: "SHOW_MODAL",
    name,
    opts,
  };
}

export function hideModal(name: string): Action {
  return {
    type: "HIDE_MODAL",
    name,
  };
}
