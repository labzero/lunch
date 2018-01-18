import { normalize } from 'normalizr';
import update from 'immutability-helper';
import ActionTypes from '../constants/ActionTypes';
import { getRestaurantIds, getRestaurantById } from '../selectors/restaurants';
import * as schemas from '../schemas';
import isFetching from './helpers/isFetching';

export default new Map([
  [ActionTypes.SORT_RESTAURANTS, (state, action) =>
    update(state, {
      items: {
        result: {
          $apply: result => {
            const sortIndexes = {};
            result.forEach((id, index) => {
              sortIndexes[id] = index;
            });
            const sortedResult = Array.from(result).sort((a, b) => {
              if (action.newlyAdded !== undefined && action.user.id === action.newlyAdded.userId) {
                if (a === action.newlyAdded.id) { return -1; }
                if (b === action.newlyAdded.id) { return 1; }
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
            // If array contents match, return original (for shallow comparison)
            return sortedResult.some((r, i) => r !== result[i]) ? sortedResult : result;
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
        isFetching: true
      }
    })
  ],
  [ActionTypes.RECEIVE_RESTAURANTS, (state, action) =>
    update(state, {
      $merge: {
        isFetching: false,
        didInvalidate: false,
        items: normalize(action.items, [schemas.restaurant])
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
          restaurants: state.items.entities.restaurants ? {
            $merge: {
              [action.restaurant.id]: action.restaurant
            }
          } : {
            $set: {
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
              },
              all_vote_count: {
                $apply: count => parseInt(count, 10) + 1
              }
            }
          },
          votes: state.items.entities.votes ? {
            $merge: {
              [action.vote.id]: action.vote
            }
          } : {
            $set: {
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
                $splice: [[
                  getRestaurantById(
                    { restaurants: state },
                    action.restaurantId
                  ).votes.indexOf(action.id),
                  1
                ]]
              },
              all_vote_count: {
                $apply: count => parseInt(count, 10) - 1
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
                $splice: [[
                  getRestaurantById(
                    { restaurants: state },
                    action.restaurantId
                  ).tags.indexOf(action.id),
                  1
                ]]
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
              const changedRestaurants = Object.assign({}, r);
              Object.keys(changedRestaurants).forEach(i => {
                if (changedRestaurants[i].tags.indexOf(action.id) > -1) {
                  changedRestaurants[i].tags = update(changedRestaurants[i].tags, {
                    $splice: [[changedRestaurants[i].tags.indexOf(action.id), 1]]
                  });
                }
              });
              return changedRestaurants;
            }
          }
        }
      }
    })
  ],
  [ActionTypes.DECISION_POSTED, (state, action) =>
    update(state, {
      items: {
        entities: {
          restaurants: {
            $apply: r => {
              const decision = r[action.decision.restaurant_id];
              // eslint-disable-next-line no-param-reassign
              r[action.decision.restaurant_id] = {
                ...r[action.decision.restaurant_id],
                all_decision_count: parseInt(decision.all_decision_count, 10) + 1,
              };
              action.deselected.forEach(i => {
                // eslint-disable-next-line no-param-reassign
                r[i.restaurant_id] = {
                  ...r[i.restaurant_id],
                  all_decision_count: parseInt(r[i.restaurant_id].all_decision_count, 10) - 1,
                };
              });
              return r;
            }
          }
        }
      }
    })
  ],
  [ActionTypes.DECISION_DELETED, (state, action) =>
    update(state, {
      items: {
        entities: {
          restaurants: {
            [action.restaurantId]: {
              all_decision_count: {
                $apply: count => parseInt(count, 10) - 1
              }
            }
          }
        }
      }
    })
  ],
  [ActionTypes.SET_NAME_FILTER, (state, action) =>
    update(state, {
      nameFilter: {
        $set: action.val
      }
    })
  ]
]);
