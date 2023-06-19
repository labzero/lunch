import nodeCrypto from "crypto";
import { Notification, Reducer } from "../interfaces";
import canUseDOM from "../helpers/canUseDOM";

const crypto = canUseDOM ? window.crypto : nodeCrypto;

const notifications: Reducer<"notifications"> = (state, action) => {
  switch (action.type) {
    case "NOTIFY": {
      const { realAction } = action;
      const baseNotification = {
        actionType: realAction.type,
        id: crypto.randomUUID(),
      };
      let notification: Notification;
      switch (realAction.type) {
        case "RESTAURANT_POSTED": {
          const { userId, restaurant } = realAction;
          notification = {
            ...baseNotification,
            vals: {
              userId,
              restaurant,
            },
          };
          break;
        }
        case "RESTAURANT_DELETED": {
          const { userId, id } = realAction;
          notification = {
            ...baseNotification,
            vals: {
              userId,
              restaurantId: id,
            },
          };
          break;
        }
        case "RESTAURANT_RENAMED": {
          const { id, fields, userId } = realAction;
          notification = {
            ...baseNotification,
            vals: {
              userId,
              restaurantId: id,
              newName: fields.name,
            },
          };
          break;
        }
        case "VOTE_POSTED": {
          notification = {
            ...baseNotification,
            vals: {
              userId: realAction.vote.userId,
              restaurantId: realAction.vote.restaurantId,
            },
          };
          break;
        }
        case "VOTE_DELETED": {
          const { userId, restaurantId } = realAction;
          notification = {
            ...baseNotification,
            vals: {
              userId,
              restaurantId,
            },
          };
          break;
        }
        case "POSTED_NEW_TAG_TO_RESTAURANT": {
          const { userId, restaurantId, tag } = realAction;
          notification = {
            ...baseNotification,
            vals: {
              userId,
              restaurantId,
              tag,
            },
          };
          break;
        }
        case "POSTED_TAG_TO_RESTAURANT": {
          const { userId, restaurantId, id } = realAction;
          notification = {
            ...baseNotification,
            vals: {
              userId,
              restaurantId,
              tagId: id,
            },
          };
          break;
        }
        case "DELETED_TAG_FROM_RESTAURANT": {
          const { userId, restaurantId, id } = realAction;
          notification = {
            ...baseNotification,
            vals: {
              userId,
              restaurantId,
              tagId: id,
            },
          };
          break;
        }
        case "TAG_DELETED": {
          const { userId, id } = realAction;
          notification = {
            ...baseNotification,
            vals: {
              userId,
              tagId: id,
            },
          };
          break;
        }
        case "DECISION_POSTED": {
          const { userId, decision } = realAction;
          notification = {
            ...baseNotification,
            vals: {
              decision,
              userId,
              restaurantId: decision.restaurantId,
            },
          };
          break;
        }
        case "DECISIONS_DELETED": {
          const { decisions, userId } = realAction;
          notification = {
            ...baseNotification,
            vals: {
              userId,
              restaurantId: decisions[0].restaurantId,
            },
          };
          break;
        }
        default: {
          return state;
        }
      }

      return [...state.slice(-3), notification];
    }
    case "EXPIRE_NOTIFICATION": {
      return state.filter((n) => n.id !== action.id);
    }
    default:
      break;
  }
  return state;
};

export default notifications;
