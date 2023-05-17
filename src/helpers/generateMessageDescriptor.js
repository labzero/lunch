import * as messages from "../core/messages";
import get from "./get";

export const globalMessageDescriptor = (id) => ({
  id,
  defaultMessage: get(messages.en, id),
});

export default (component) => (id) => {
  const namespacedId = `${component}.${id}`;
  return globalMessageDescriptor(namespacedId);
};
