import { StateHelpers } from "../interfaces";

export default function createHelpers({ fetch, history }: StateHelpers) {
  return {
    fetch,
    history,
  };
}
