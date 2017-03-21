import { createSelector } from 'reselect';
import * as messages from '../core/messages';

export const getLocale = state => state.locale;
export const getMessages = createSelector(
  getLocale,
  locale => {
    const messagesForLocale = messages[locale];
    const flattenedMessages = {};
    Object.keys(messagesForLocale).forEach(component => {
      const messagesForComponent = messagesForLocale[component];
      if (typeof messagesForComponent === 'string') {
        flattenedMessages[component] = messagesForComponent;
      } else {
        Object.keys(messagesForComponent).forEach(id => {
          flattenedMessages[`${component}.${id}`] = messagesForComponent[id];
        });
      }
    });
    return flattenedMessages;
  }
);
