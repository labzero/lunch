import uuidV1 from 'uuid/v1';
import ActionTypes from '../constants/ActionTypes';

export default new Map([
  [ActionTypes.NOTIFY, (state, action) => {
    const { realAction } = action;
    const notification = {
      actionType: realAction.type,
      id: uuidV1()
    };
    switch (notification.actionType) {
      case ActionTypes.RESTAURANT_POSTED: {
        const { userId, restaurant } = realAction;
        notification.vals = {
          userId,
          restaurant,
          restaurantId: restaurant.id
        };
        break;
      }
      case ActionTypes.RESTAURANT_DELETED: {
        const { userId, id } = realAction;
        notification.vals = {
          userId,
          restaurantId: id
        };
        break;
      }
      case ActionTypes.RESTAURANT_RENAMED: {
        const { id, fields, userId } = realAction;
        notification.vals = {
          userId,
          restaurantId: id,
          newName: fields.name
        };
        break;
      }
      case ActionTypes.VOTE_POSTED: {
        notification.vals = {
          userId: realAction.vote.user_id,
          restaurantId: realAction.vote.restaurant_id
        };
        break;
      }
      case ActionTypes.VOTE_DELETED: {
        const { userId, restaurantId } = realAction;
        notification.vals = {
          userId,
          restaurantId
        };
        break;
      }
      case ActionTypes.POSTED_NEW_TAG_TO_RESTAURANT: {
        const { userId, restaurantId, tag } = realAction;
        notification.vals = {
          userId,
          restaurantId,
          tag
        };
        break;
      }
      case ActionTypes.POSTED_TAG_TO_RESTAURANT: {
        const { userId, restaurantId, id } = realAction;
        notification.vals = {
          userId,
          restaurantId,
          tagId: id
        };
        break;
      }
      case ActionTypes.DELETED_TAG_FROM_RESTAURANT: {
        const { userId, restaurantId, id } = realAction;
        notification.vals = {
          userId,
          restaurantId,
          tagId: id
        };
        break;
      }
      case ActionTypes.TAG_DELETED: {
        const { userId, id } = realAction;
        notification.vals = {
          userId,
          tagId: id
        };
        break;
      }
      case ActionTypes.DECISION_POSTED: {
        const { userId, decision } = realAction;
        notification.vals = {
          userId,
          restaurantId: decision.restaurant_id
        };
        break;
      }
      case ActionTypes.DECISION_DELETED: {
        const { restaurantId, userId } = realAction;
        notification.vals = {
          userId,
          restaurantId
        };
        break;
      }
      default: {
        return state;
      }
    }
    return [
      ...state.slice(-3),
      notification
    ];
  }],
  [ActionTypes.EXPIRE_NOTIFICATION, (state, action) =>
    state.filter(n => n.id !== action.id)
  ]
]);
