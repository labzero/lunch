import ActionTypes from './constants/ActionTypes';
import { getRestaurantIds, getRestaurantById } from './selectors/restaurants';
import { getTagIds, getTagById } from './selectors/tags';
import { getWhitelistEmailIds } from './selectors/whitelistEmails';
import * as schemas from './schemas';
import { normalize, arrayOf } from 'normalizr';
import update from 'react-addons-update';
import uuid from 'node-uuid';

const setOrMerge = (target, key, obj) => {
  if (target[key] === undefined) {
    return update(target, {
      [key]: {
        $set: obj
      }
    });
  }
  return update(target, {
    [key]: {
      $merge: obj
    }
  });
};

const isFetching = state =>
  update(state, {
    $merge: {
      isFetching: true
    }
  });

export const restaurants = new Map([
  [ActionTypes.SORT_RESTAURANTS, (state, action) =>
    update(state, {
      items: {
        result: {
          $apply: result => {
            const sortIndexes = {};
            result.forEach((id, index) => {
              sortIndexes[id] = index;
            });
            return result.sort((a, b) => {
              if (action.newlyAdded !== undefined) {
                if (a === action.newlyAdded) { return -1; }
                if (b === action.newlyAdded) { return 1; }
              }
              if (action.decision !== null) {
                if (action.decision.restaurant_id === a) { return -1; }
                if (action.decision.restaurant_id === b) { return 1; }
              }
              const restaurantA = getRestaurantById({ restaurants: state }, a);
              const restaurantB = getRestaurantById({ restaurants: state }, b);

              // stable sort
              if (restaurantA.votes.length !== restaurantB.votes.length) {
                return restaurantB.votes.length - restaurantA.votes.length;
              }
              return sortIndexes[a] - sortIndexes[b];
            });
          }
        }
      }
    })
  ],
  [ActionTypes.INVALIDATE_RESTAURANTS, state =>
    update(state, {
      $merge: {
        didInvalidate: true
      }
    })
  ],
  [ActionTypes.REQUEST_RESTAURANTS, state =>
    update(state, {
      $merge: {
        isFetching: true,
        didInvalidate: false
      }
    })
  ],
  [ActionTypes.RECEIVE_RESTAURANTS, (state, action) =>
    update(state, {
      $merge: {
        isFetching: false,
        didInvalidate: false,
        items: normalize(action.items, arrayOf(schemas.restaurant))
      }
    })
  ],
  [ActionTypes.POST_RESTAURANT, isFetching],
  [ActionTypes.RESTAURANT_POSTED, (state, action) =>
    update(state, {
      isFetching: {
        $set: false
      },
      items: {
        result: {
          $unshift: [action.restaurant.id]
        },
        entities: {
          restaurants: {
            $merge: {
              [action.restaurant.id]: action.restaurant
            }
          }
        }
      }
    })
  ],
  [ActionTypes.DELETE_RESTAURANT, isFetching],
  [ActionTypes.RESTAURANT_DELETED, (state, action) =>
    update(state, {
      isFetching: {
        $set: false
      },
      items: {
        result: {
          $splice: [[getRestaurantIds({ restaurants: state }).indexOf(action.id), 1]]
        }
      }
    })
  ],
  [ActionTypes.RENAME_RESTAURANT, isFetching],
  [ActionTypes.RESTAURANT_RENAMED, (state, action) =>
    update(state, {
      isFetching: {
        $set: false
      },
      items: {
        entities: {
          restaurants: {
            [action.id]: {
              $merge: action.fields
            }
          }
        }
      }
    })
  ],
  [ActionTypes.POST_VOTE, isFetching],
  [ActionTypes.VOTE_POSTED, (state, action) =>
    update(state, {
      isFetching: {
        $set: false
      },
      items: {
        entities: {
          restaurants: {
            [action.vote.restaurant_id]: {
              votes: {
                $push: [action.vote.id]
              }
            }
          },
          votes: {
            $merge: {
              [action.vote.id]: action.vote
            }
          }
        }
      }
    })
  ],
  [ActionTypes.DELETE_VOTE, isFetching],
  [ActionTypes.VOTE_DELETED, (state, action) =>
    update(state, {
      isFetching: {
        $set: false
      },
      items: {
        entities: {
          restaurants: {
            [action.restaurantId]: {
              votes: {
                $splice: [[getRestaurantById({ restaurants: state }, action.restaurantId).votes.indexOf(action.id), 1]]
              }
            }
          }
        }
      }
    })
  ],
  [ActionTypes.POST_NEW_TAG_TO_RESTAURANT, isFetching],
  [ActionTypes.POSTED_NEW_TAG_TO_RESTAURANT, (state, action) =>
    update(state, {
      isFetching: {
        $set: false
      },
      items: {
        entities: {
          restaurants: {
            [action.restaurantId]: {
              tags: {
                $push: [action.tag.id]
              }
            }
          }
        }
      }
    })
  ],
  [ActionTypes.POST_TAG_TO_RESTAURANT, isFetching],
  [ActionTypes.POSTED_TAG_TO_RESTAURANT, (state, action) =>
    update(state, {
      isFetching: {
        $set: false
      },
      items: {
        entities: {
          restaurants: {
            [action.restaurantId]: {
              tags: {
                $push: [action.id]
              }
            }
          }
        }
      }
    })
  ],
  [ActionTypes.DELETE_TAG_FROM_RESTAURANT, isFetching],
  [ActionTypes.DELETED_TAG_FROM_RESTAURANT, (state, action) =>
    update(state, {
      isFetching: {
        $set: false
      },
      items: {
        entities: {
          restaurants: {
            [action.restaurantId]: {
              tags: {
                $splice: [[getRestaurantById({ restaurants: state }, action.restaurantId).tags.indexOf(action.id), 1]]
              }
            }
          }
        }
      }
    })
  ],
  [ActionTypes.TAG_DELETED, (state, action) =>
    update(state, {
      items: {
        entities: {
          restaurants: {
            $apply: r => {
              for (const i in r) {
                if (r.hasOwnProperty(i) && r[i].tags.indexOf(action.id) > -1) {
                  r[i].tags = update(r[i].tags, {
                    $splice: [[r[i].tags.indexOf(action.id), 1]]
                  });
                }
              }
              return r;
            }
          }
        }
      }
    })
  ]
]);

export const flashes = new Map([
  [ActionTypes.FLASH_ERROR, (state, action) =>
    [
      ...state,
      {
        message: action.message,
        type: 'error'
      }
    ]
  ],
  [ActionTypes.EXPIRE_FLASH, (state, action) =>
    Array.from(state).splice(action.id, 1)
  ]
]);

export const notifications = new Map([
  [ActionTypes.NOTIFY, (state, action) => {
    const { realAction } = action;
    const notification = {
      actionType: realAction.type,
      id: uuid.v1()
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

const resetRestaurant = (state, action) =>
  update(state, {
    $merge: {
      [action.id]: {
        $set: {}
      }
    }
  });

const resetAddTagAutosuggestValue = (state, action) =>
  update(state, {
    $apply: target => setOrMerge(target, action.restaurantId, { addTagAutosuggestValue: '' })
  });

export const listUi = new Map([
  [ActionTypes.RECEIVE_RESTAURANTS, () => {}],
  [ActionTypes.RESTAURANT_RENAMED, resetRestaurant],
  [ActionTypes.RESTAURANT_POSTED, (state, action) =>
    resetRestaurant(update(state, {
      newlyAdded: {
        $set: action.restaurant.id
      }
    }), action)
  ],
  [ActionTypes.RESTAURANT_DELETED, resetRestaurant],
  [ActionTypes.POSTED_TAG_TO_RESTAURANT, resetAddTagAutosuggestValue],
  [ActionTypes.POSTED_NEW_TAG_TO_RESTAURANT, resetAddTagAutosuggestValue],
  [ActionTypes.SET_ADD_TAG_AUTOSUGGEST_VALUE, (state, action) =>
    update(state, {
      $apply: target => setOrMerge(target, action.id, { addTagAutosuggestValue: action.value })
    })
  ],
  [ActionTypes.SHOW_ADD_TAG_FORM, (state, action) =>
    update(state, {
      $apply: target => setOrMerge(target, action.id, { isAddingTags: true })
    })
  ],
  [ActionTypes.HIDE_ADD_TAG_FORM, (state, action) =>
    update(state, {
      $apply: target => setOrMerge(target, action.id, { isAddingTags: false })
    })
  ],
  [ActionTypes.SET_EDIT_NAME_FORM_VALUE, (state, action) =>
    update(state, {
      $apply: target => setOrMerge(target, action.id, { editNameFormValue: action.value })
    })
  ],
  [ActionTypes.SHOW_EDIT_NAME_FORM, (state, action) =>
    update(state, {
      $apply: target => setOrMerge(target, action.id, { isEditingName: true })
    })
  ],
  [ActionTypes.HIDE_EDIT_NAME_FORM, (state, action) =>
    update(state, {
      $apply: target => setOrMerge(target, action.id, { isEditingName: false })
    })
  ]
]);

export const mapUi = new Map([
  [ActionTypes.RECEIVE_RESTAURANTS, () =>
    ({
      markers: {},
      showUnvoted: true
    })
  ],
  [ActionTypes.RESTAURANT_POSTED, resetRestaurant],
  [ActionTypes.RESTAURANT_DELETED, resetRestaurant],
  [ActionTypes.SHOW_INFO_WINDOW, (state, action) =>
    update(state, {
      center: {
        $set: action.latLng
      },
      markers: {
        $apply: target => setOrMerge(target, action.id, { showInfoWindow: true })
      }
    })
  ],
  [ActionTypes.HIDE_INFO_WINDOW, (state, action) =>
    update(state, {
      markers: {
        $apply: target => setOrMerge(target, action.id, { showInfoWindow: false })
      }
    })
  ],
  [ActionTypes.HIDE_ALL_INFO_WINDOWS, state =>
    update(state, {
      markers: {
        $apply: markers => {
          for (const i in markers) {
            if (markers.hasOwnProperty(i)) {
              markers[i].showInfoWindow = false;
            }
          }
          return markers;
        }
      }
    })
  ],
  [ActionTypes.SET_SHOW_UNVOTED, (state, action) =>
    update(state, {
      $merge: {
        showUnvoted: action.val
      }
    })
  ],
  [ActionTypes.CLEAR_CENTER, state =>
    update(state, {
      center: {
        $set: undefined
      }
    })
  ],
  [ActionTypes.CREATE_TEMP_MARKER, (state, action) =>
    update(state, {
      center: {
        $set: action.result.latLng
      },
      tempMarker: {
        $set: action.result
      }
    })
  ],
  [ActionTypes.CLEAR_TEMP_MARKER, state =>
    update(state, {
      center: {
        $set: undefined
      },
      tempMarker: {
        $set: undefined
      }
    })
  ]
]);

export const pageUi = new Map([
  [ActionTypes.SCROLL_TO_TOP, state =>
    update(state, {
      $merge: {
        shouldScrollToTop: true
      }
    })
  ],
  [ActionTypes.SCROLLED_TO_TOP, state =>
    update(state, {
      $merge: {
        shouldScrollToTop: false
      }
    })
  ],
]);

export const modals = new Map([
  [ActionTypes.SHOW_MODAL, (state, action) =>
    update(state, {
      $merge: {
        [action.name]: {
          shown: true,
          ...action.opts
        }
      }
    })
  ],
  [ActionTypes.HIDE_MODAL, (state, action) =>
    update(state, {
      $apply: target => setOrMerge(target, action.name, { shown: false })
    })
  ],
  [ActionTypes.RESTAURANT_DELETED, state =>
    update(state, {
      $apply: target => setOrMerge(target, 'deleteRestaurant', { shown: false })
    })
  ],
  [ActionTypes.TAG_DELETED, state =>
    update(state, {
      $apply: target => setOrMerge(target, 'deleteTag', { shown: false })
    })
  ]
]);

export const tags = new Map([
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
          tags: {
            $merge: {
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
    update(state, {
      isFetching: {
        $set: false
      },
      items: {
        result: {
          $splice: [[getTagIds({ tags: state }).indexOf(action.id), 1]]
        }
      }
    })
  ]
]);

export const tagUi = new Map([
  [ActionTypes.SHOW_TAG_FILTER_FORM, state =>
    update(state, {
      filterForm: {
        $merge: {
          shown: true
        }
      }
    })
  ],
  [ActionTypes.HIDE_TAG_FILTER_FORM, state =>
    update(state, {
      filterForm: {
        $merge: {
          autosuggestValue: '',
          shown: false
        }
      }
    })
  ],
  [ActionTypes.SET_TAG_FILTER_AUTOSUGGEST_VALUE, (state, action) =>
    update(state, {
      filterForm: {
        $merge: {
          autosuggestValue: action.value
        }
      }
    })
  ],
  [ActionTypes.ADD_TAG_FILTER, state =>
    update(state, {
      filterForm: {
        $merge: {
          autosuggestValue: ''
        }
      }
    })
  ],
  [ActionTypes.SHOW_TAG_EXCLUSION_FORM, state =>
    update(state, {
      exclusionForm: {
        $merge: {
          shown: true
        }
      }
    })
  ],
  [ActionTypes.HIDE_TAG_EXCLUSION_FORM, state =>
    update(state, {
      exclusionForm: {
        $merge: {
          autosuggestValue: '',
          shown: false
        }
      }
    })
  ],
  [ActionTypes.SET_TAG_EXCLUSION_AUTOSUGGEST_VALUE, (state, action) =>
    update(state, {
      exclusionForm: {
        $merge: {
          autosuggestValue: action.value
        }
      }
    })
  ],
  [ActionTypes.ADD_TAG_EXCLUSION, state =>
    update(state, {
      exclusionForm: {
        $merge: {
          autosuggestValue: ''
        }
      }
    })
  ]
]);

export const tagFilters = new Map([
  [ActionTypes.ADD_TAG_FILTER, (state, action) =>
    [
      ...state,
      action.id
    ]
  ],
  [ActionTypes.REMOVE_TAG_FILTER, (state, action) =>
    state.filter(t => t !== action.id)
  ],
  [ActionTypes.HIDE_TAG_FILTER_FORM, () => []]
]);

export const tagExclusions = new Map([
  [ActionTypes.ADD_TAG_EXCLUSION, (state, action) =>
    [
      ...state,
      action.id
    ]
  ],
  [ActionTypes.REMOVE_TAG_EXCLUSION, (state, action) =>
    state.filter(t => t !== action.id)
  ],
  [ActionTypes.HIDE_TAG_EXCLUSION_FORM, () => []]
]);

export const decision = new Map([
  [ActionTypes.POST_DECISION, isFetching],
  [ActionTypes.DECISION_POSTED, (state, action) =>
    update(state, {
      isFetching: {
        $set: false
      },
      inst: {
        $set: action.decision
      }
    })
  ],
  [ActionTypes.DELETE_DECISION, isFetching],
  [ActionTypes.DECISION_DELETED, (state) =>
    update(state, {
      isFetching: {
        $set: false
      },
      inst: {
        $set: null
      }
    })
  ]
]);

export const whitelistEmails = new Map([
  [ActionTypes.DELETE_WHITELIST_EMAIL, isFetching],
  [ActionTypes.WHITELIST_EMAIL_DELETED, (state, action) =>
    update(state, {
      isFetching: {
        $set: false
      },
      items: {
        result: {
          $splice: [[getWhitelistEmailIds({ whitelistEmails: state }).indexOf(action.id), 1]]
        }
      }
    })
  ],
  [ActionTypes.POST_WHITELIST_EMAIL, isFetching],
  [ActionTypes.WHITELIST_EMAIL_POSTED, (state, action) =>
    update(state, {
      items: {
        result: {
          $push: [action.whitelistEmail.id]
        },
        entities: {
          $apply: target => setOrMerge(target, 'whitelistEmails', { [action.whitelistEmail.id]: action.whitelistEmail })
        }
      }
    })
  ]
]);

export const whitelistEmailUi = new Map([
  [ActionTypes.SET_EMAIL_WHITELIST_INPUT_VALUE, (state, action) =>
    update(state, {
      inputValue: {
        $set: action.value
      }
    })
  ],
  [ActionTypes.WHITELIST_EMAIL_POSTED, state =>
    update(state, {
      inputValue: {
        $set: ''
      }
    })
  ]
]);

export const latLng = new Map();
export const user = new Map();
export const users = new Map();
export const wsPort = new Map();
