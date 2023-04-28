import { normalize } from 'normalizr';
import update, { Spec } from 'immutability-helper';
import { getRestaurantIds, getRestaurantById } from '../selectors/restaurants';
import * as schemas from '../schemas';
import isFetching from './helpers/isFetching';
import { Reducer } from '../interfaces';
import maybeAddToString from '../helpers/maybeAddToString';

const restaurants: Reducer<"restaurants"> = (state, action) => {
  switch(action.type) {
    case "SORT_RESTAURANTS": {
      return update(state, {
        items: {
          result: {
            $apply: (result: number[]) => {
              const sortIndexes: {[index: number]: number} = {};
              result.forEach((id, index) => {
                sortIndexes[id] = index;
              });
              const sortedResult = Array.from(result).sort((a, b) => {
                if (action.newlyAdded !== undefined && action.user.id === action.newlyAdded.userId) {
                  if (a === action.newlyAdded.id) { return -1; }
                  if (b === action.newlyAdded.id) { return 1; }
                }
                if (action.decision !== undefined) {
                  if (action.decision.restaurantId === a) { return -1; }
                  if (action.decision.restaurantId === b) { return 1; }
                }
                const restaurantA = getRestaurantById({ restaurants: state }, a);
                const restaurantB = getRestaurantById({ restaurants: state }, b);

                if (restaurantA.votes.length !== restaurantB.votes.length) {
                  return restaurantB.votes.length - restaurantA.votes.length;
                }
                if (restaurantA.all_decision_count !== restaurantB.all_decision_count) {
                  return restaurantA.all_decision_count - restaurantB.all_decision_count;
                }
                if (restaurantA.all_vote_count !== restaurantB.all_vote_count) {
                  return restaurantB.all_vote_count - restaurantA.all_vote_count;
                }
                // stable sort
                return sortIndexes[a] - sortIndexes[b];
              });
                // If array contents match, return original (for shallow comparison)
              return sortedResult.some((r, i) => r !== result[i]) ? sortedResult : result;
            }
          }
        }
      });
    }
    case "INVALIDATE_RESTAURANTS": {
      return update(state, {
        $merge: {
          didInvalidate: true
        }
      })
    }
    case "REQUEST_RESTAURANTS": {
      return update(state, {
        $merge: {
          isFetching: true
        }
      })
    }
    case "RECEIVE_RESTAURANTS": {
      return update(state, {
        $merge: {
          isFetching: false,
          didInvalidate: false,
          items: normalize(action.items, [schemas.restaurant])
        }
      })
    }
    case "POST_RESTAURANT":
    case "DELETE_RESTAURANT":
    case "RENAME_RESTAURANT":
    case "POST_VOTE":
    case "DELETE_VOTE":
    case "POST_NEW_TAG_TO_RESTAURANT":
    case "POST_TAG_TO_RESTAURANT":
    case "DELETE_TAG_FROM_RESTAURANT": {
      return isFetching(state);
    }
    case "RESTAURANT_POSTED": {
      return update(state, {
        isFetching: {
          $set: false
        },
        items: {
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
          },
          result: {
            $apply: (result: number[]) => {
              if (result.indexOf(action.restaurant.id) === -1) {
                return [action.restaurant.id, ...result];
              }
              return result;
            }
          }
        }
      });
    }
    case "RESTAURANT_DELETED": {
      return update(state, {
        isFetching: {
          $set: false
        },
        items: {
          result: {
            $splice: [[getRestaurantIds({ restaurants: state }).indexOf(action.id), 1]]
          }
        }
      })
    }
    case "RESTAURANT_RENAMED": {
      return update(state, {
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
    }
    case "VOTE_POSTED": {
      const updates: Spec<typeof state> = {
        isFetching: {
          $set: false
        },
        items: {
          entities: {
            votes: state.items.entities.votes ? {
              $merge: {
                [action.vote.id]: action.vote
              }
            } : {
              $set: {
                [action.vote.id]: action.vote
              }
            },
            restaurants: {
              $apply: (restaurants) => {
                if (restaurants[action.vote.restaurantId].votes.indexOf(action.vote.id) === -1) {
                  const restaurant = restaurants[action.vote.restaurantId]
                  restaurants = {
                    ...restaurants,
                    [action.vote.restaurantId]: {
                      ...restaurant,
                      votes: [...restaurant.votes, action.vote.id],
                      all_vote_count: maybeAddToString(restaurant.all_vote_count, 1)
                    }
                  }
                }
                return restaurants;
              }
            }
          }
        }
      };

      return update(state, updates);
    }
    case "VOTE_DELETED": {
      return update(state, {
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
                  $apply: count => maybeAddToString(count, -1)
                }
              }
            }
          }
        }
      })
    }
    case "POSTED_NEW_TAG_TO_RESTAURANT": {
      return update(state, {
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
    }
    case "POSTED_TAG_TO_RESTAURANT": {
      const updates: Spec<typeof state> = {
        isFetching: {
          $set: false
        }
      };

      if (state.items.entities.restaurants[action.restaurantId].tags.indexOf(action.id) === -1) {
        updates.items = {
          entities: {
            restaurants: {
              [action.restaurantId]: {
                tags: {
                  $push: [action.id]
                }
              }
            }
          }
        };
      }

      return update(state, updates);
    }
    case "DELETED_TAG_FROM_RESTAURANT": {
      return update<typeof state>(state, {
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
    }
    case "TAG_DELETED": {
      return update(state, {
        items: {
          entities: {
            restaurants: {
              $apply: r => {
                const changedRestaurants = { ...r };
                Object.keys(changedRestaurants).forEach(i => {
                  const index = Number(i);
                  const changedRestaurant = changedRestaurants[index];
                  if (changedRestaurant.tags.indexOf(action.id) > -1) {
                    changedRestaurants[index] = update(changedRestaurant, {
                      $merge: {
                        tags: update(changedRestaurant.tags, {
                          $splice: [[changedRestaurant.tags.indexOf(action.id), 1]]
                        })
                      }
                    });
                  }
                });
                return changedRestaurants;
              }
            }
          }
        }
      })
    }
    case "DECISION_POSTED": {
      return update(state, {
        items: {
          entities: {
            restaurants: {
              $apply: r => {
                const decision = r[action.decision.restaurantId];
                // eslint-disable-next-line no-param-reassign
                r[action.decision.restaurantId] = {
                  ...r[action.decision.restaurantId],
                  all_decision_count: maybeAddToString(decision.all_decision_count, 1),
                };
                action.deselected.forEach(i => {
                  // eslint-disable-next-line no-param-reassign
                  r[i.restaurantId] = {
                    ...r[i.restaurantId],
                    all_decision_count: maybeAddToString(r[i.restaurantId].all_decision_count, -1)
                  };
                });
                return r;
              }
            }
          }
        }
      })
    }
    case "DECISIONS_DELETED": {      
      return update(state, {
        items: {
          entities: {
            restaurants: {
              $apply: (restaurants) => {
                action.decisions.forEach((decision) => {
                  const restaurant = restaurants[decision.restaurantId];
                  restaurants[decision.restaurantId] = {
                    ...restaurant,
                    all_decision_count: maybeAddToString(restaurant.all_decision_count, -1)
                  }
                });
                return restaurants;
              }
            }
          },
        },
      });
    }
    case "SET_NAME_FILTER": {
      return update(state, {
        nameFilter: {
          $set: action.val
        }
      })
    }
  }
  return state;
};

export default restaurants;
