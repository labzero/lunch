import * as messages from "../core/messages";
import get from "./get";

export const globalMessageDescriptor = (id: string) => ({
  id,
  defaultMessage: get(messages.en, id),
});

export default (component: string) => (id: string) => {
  const namespacedId = `${component}.${id}`;
  return globalMessageDescriptor(namespacedId);
};
