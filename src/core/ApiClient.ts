import { Dispatch } from "redux";
import { flashError } from "../actions/flash";
import history from "../history";

export async function processResponse(response: Response, dispatch?: Dispatch) {
  if (response.status === 204) {
    return undefined;
  }
  try {
    const json = await response.json();
    if (response.status >= 400) {
      throw new Error(json.data.message);
    }
    return json.data;
  } catch (err: any) {
    if (response.status >= 400) {
      if (response.status === 401) {
        history!.replace(`/login?next=${history!.location.pathname}`);
      } else {
        if (dispatch) {
          dispatch(flashError(err.message));
        }
        // returning a rejection instead of throwing an error prevents
        // react-error-overlay from triggering.
        return Promise.reject(err.message);
      }
    }
    return undefined;
  }
}

export const credentials = "same-origin";
export const jsonHeaders = {
  Accept: "application/json",
  "Content-Type": "application/json",
};
