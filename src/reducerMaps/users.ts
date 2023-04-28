import { normalize } from 'normalizr';
import update from 'immutability-helper';
import { getUserIds } from '../selectors/users';
import * as schemas from '../schemas';
import isFetching from './helpers/isFetching';
import { Reducer } from '../interfaces';

const users: Reducer<"users"> = (state, action) => {
  switch(action.type) {
    case "INVALIDATE_USERS": {
      return update(state, {
        $merge: {
          didInvalidate: true,
        },
      })
    }
    case "REQUEST_USERS": {
      return update(state, {
        $merge: {
          isFetching: true,
        },
      });
    }
    case "RECEIVE_USERS": {
      return update(state, {
        $merge: {
          isFetching: false,
          didInvalidate: false,
          items: normalize(action.items, [schemas.user]),
        },
      })
    }
    case "DELETE_USER":
    case "POST_USER":
    case "PATCH_USER": {
      return isFetching(state);
    }
    case "USER_DELETED": {
      return update(state, {
        isFetching: {
          $set: false,
        },
        items: {
          result: {
            $splice: [[getUserIds({ users: state }).indexOf(action.id), 1]],
          },
        },
      })
    }
    case "USER_POSTED": {
      return update(state, {
        items: {
          result: {
            $push: [action.user.id],
          },
          entities: {
            users: state.items.entities.users
              ? {
                $merge: {
                  [action.user.id]: action.user,
                },
              }
              : {
                $set: {
                  [action.user.id]: action.user,
                },
              },
          },
        },
      })
    }
    case "USER_PATCHED": {
      return update(state, {
        isFetching: {
          $set: false,
        },
        items: {
          entities: {
            users: {
              [action.id]: {
                $merge: action.user,
              },
            },
          },
        },
      })
    }
  }
  return state;
}

export default users;
