import { Dispatch } from "redux";
import { flashError } from "../actions/flash";
import history from "../history";

export function processResponse(response: Response, dispatch: Dispatch) {
  return response
    .json()
    .then((json) => {
      if (response.status >= 400) {
        throw new Error(json.data.message);
      }
      return json.data;
    })
    .catch((err) => {
      // no json - possibly a 204 response
      if (response.status >= 400) {
        if (response.status === 401) {
          history!.replace(`/login?next=${history!.location.pathname}`);
        } else {
          dispatch(flashError(err.message));
          // returning a rejection instead of throwing an error prevents
          // react-error-overlay from triggering.
          return Promise.reject(err.message);
        }
      }
      return undefined;
    });
}

export const credentials = "same-origin";
export const jsonHeaders = {
  Accept: "application/json",
  "Content-Type": "application/json",
};
