import { createSelector } from "reselect";
import * as messages from "../core/messages";
import { State } from "../interfaces";

export const getLocale = (state: State) => state.locale;
export const getMessages = createSelector(getLocale, (locale) => {
  const messagesForLocale = messages[locale];
  const flattenedMessages: { [index: string]: string } = {};
  Object.keys(messagesForLocale).forEach((component) => {
    const componentKey = component as keyof typeof messagesForLocale;
    const messagesForComponent = messagesForLocale[componentKey];
    if (typeof messagesForComponent === "string") {
      flattenedMessages[componentKey] = messagesForComponent;
    } else {
      Object.keys(messagesForComponent).forEach((id) => {
        const idKey = id as keyof typeof messagesForComponent;
        flattenedMessages[`${componentKey}.${id}`] =
          messagesForComponent[idKey];
      });
    }
  });
  return flattenedMessages;
});
