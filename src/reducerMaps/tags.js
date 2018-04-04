import { normalize } from 'normalizr';
import update from 'immutability-helper';
import ActionTypes from '../constants/ActionTypes';
import { getTagIds, getTagById } from '../selectors/tags';
import * as schemas from '../schemas';
import isFetching from './helpers/isFetching';

export default new Map([
  [ActionTypes.INVALIDATE_TAGS, state =>
    update(state, {
      $merge: {
        didInvalidate: true
      }
    })
  ],
  [ActionTypes.REQUEST_TAGS, state =>
    update(state, {
      $merge: {
        isFetching: true
      }
    })
  ],
  [ActionTypes.RECEIVE_TAGS, (state, action) =>
    update(state, {
      $merge: {
        isFetching: false,
        didInvalidate: false,
        items: normalize(action.items, [schemas.tag])
      }
    })
  ],
  [ActionTypes.POSTED_TAG_TO_RESTAURANT, (state, action) =>
    update(state, {
      items: {
        entities: {
          tags: {
            [action.id]: {
              restaurant_count: {
                $set: parseInt(getTagById({ tags: state }, action.id).restaurant_count, 10) + 1
              }
            }
          }
        }
      }
    })
  ],
  [ActionTypes.POSTED_NEW_TAG_TO_RESTAURANT, (state, action) =>
    update(state, {
      items: {
        result: {
          $push: [action.tag.id]
        },
        entities: {
          tags: state.items.entities.tags ? {
            $merge: {
              [action.tag.id]: action.tag
            }
          } : {
            $set: {
              [action.tag.id]: action.tag
            }
          }
        }
      }
    })
  ],
  [ActionTypes.DELETED_TAG_FROM_RESTAURANT, (state, action) =>
    update(state, {
      isFetching: {
        $set: false
      },
      items: {
        entities: {
          tags: {
            [action.id]: {
              $merge: {
                restaurant_count:
                  parseInt(state.items.entities.tags[action.id].restaurant_count, 10) - 1
              }
            }
          }
        }
      }
    })
  ],
  [ActionTypes.DELETE_TAG, isFetching],
  [ActionTypes.TAG_DELETED, (state, action) =>
    {
      const tagIndex = getTagIds({ tags: state }).indexOf(action.id);
      const newState = {
        isFetching: {
          $set: false
        }
      };
      newState.items = {};
      if (tagIndex !== -1) {
        newState.items = {
          result: {
            $splice: [[tagIndex, 1]]
          }
        };
      }
      return update(state, newState)
    }
  ]
]);
