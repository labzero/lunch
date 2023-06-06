import get from "lodash.get";
import * as messages from "../core/messages";

export const globalMessageDescriptor = (id: string) => ({
  id,
  defaultMessage: get(messages.en, id),
});

export default (component: string) => (id: string) => {
  const namespacedId = `${component}.${id}`;
  return globalMessageDescriptor(namespacedId);
};
