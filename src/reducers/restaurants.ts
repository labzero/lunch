import { normalize } from "normalizr";
import { createNextState } from "@reduxjs/toolkit";
import { getRestaurantIds, getRestaurantById } from "../selectors/restaurants";
import * as schemas from "../schemas";
import { Reducer } from "../interfaces";
import maybeAddToString from "../helpers/maybeAddToString";

const restaurants: Reducer<"restaurants"> = (state, action) =>
  createNextState(state, (draftState) => {
    switch (action.type) {
      case "SORT_RESTAURANTS": {
        const sortIndexes: { [index: number]: number } = {};
        draftState.items.result.forEach((id, index) => {
          sortIndexes[id] = index;
        });
        const sortedResult = Array.from(draftState.items.result).sort(
          (a, b) => {
            if (
              action.newlyAdded !== undefined &&
              action.user.id === action.newlyAdded.userId
            ) {
              if (a === action.newlyAdded.id) {
                return -1;
              }
              if (b === action.newlyAdded.id) {
                return 1;
              }
            }
            if (action.decision !== undefined) {
              if (action.decision.restaurantId === a) {
                return -1;
              }
              if (action.decision.restaurantId === b) {
                return 1;
              }
            }
            const restaurantA = getRestaurantById({ restaurants: state }, a);
            const restaurantB = getRestaurantById({ restaurants: state }, b);

            if (restaurantA.votes.length !== restaurantB.votes.length) {
              return restaurantB.votes.length - restaurantA.votes.length;
            }
            if (
              restaurantA.all_decision_count !== restaurantB.all_decision_count
            ) {
              return (
                Number(restaurantA.all_decision_count) -
                Number(restaurantB.all_decision_count)
              );
            }
            if (restaurantA.all_vote_count !== restaurantB.all_vote_count) {
              return (
                Number(restaurantB.all_vote_count) -
                Number(restaurantA.all_vote_count)
              );
            }
            // stable sort
            return sortIndexes[a] - sortIndexes[b];
          }
        );
        // If array contents match, return original (for shallow comparison)
        if (sortedResult.some((r, i) => r !== draftState.items.result[i]))
          draftState.items.result = sortedResult;
        return;
      }
      case "INVALIDATE_RESTAURANTS": {
        draftState.didInvalidate = true;
        return;
      }
      case "RECEIVE_RESTAURANTS": {
        draftState.isFetching = false;
        draftState.didInvalidate = false;
        draftState.items = normalize(action.items, [schemas.restaurant]);
        return;
      }
      case "REQUEST_RESTAURANTS":
      case "POST_RESTAURANT":
      case "DELETE_RESTAURANT":
      case "RENAME_RESTAURANT":
      case "POST_VOTE":
      case "DELETE_VOTE":
      case "POST_NEW_TAG_TO_RESTAURANT":
      case "POST_TAG_TO_RESTAURANT":
      case "DELETE_TAG_FROM_RESTAURANT": {
        draftState.isFetching = true;
        return;
      }
      case "RESTAURANT_POSTED": {
        draftState.isFetching = false;
        draftState.items.entities.restaurants = {
          ...draftState.items.entities.restaurants,
          [action.restaurant.id]: action.restaurant,
        };
        if (draftState.items.result.indexOf(action.restaurant.id) === -1) {
          draftState.items.result.unshift(action.restaurant.id);
        }
        return;
      }
      case "RESTAURANT_DELETED": {
        draftState.isFetching = false;
        draftState.items.result.splice(
          getRestaurantIds({ restaurants: draftState }).indexOf(action.id),
          1
        );
        return;
      }
      case "RESTAURANT_RENAMED": {
        draftState.isFetching = false;
        draftState.items.entities.restaurants = {
          ...draftState.items.entities.restaurants,
          [action.id]: {
            ...draftState.items.entities.restaurants[action.id],
            ...action.fields,
          },
        };
        return;
      }
      case "VOTE_POSTED": {
        draftState.isFetching = false;
        draftState.items.entities.votes = {
          ...draftState.items.entities.votes,
          [action.vote.id]: action.vote,
        };
        const r =
          draftState.items.entities.restaurants[action.vote.restaurantId];
        if (r.votes.indexOf(action.vote.id) === -1) {
          r.votes.push(action.vote.id);
          r.all_vote_count = maybeAddToString(r.all_vote_count, 1);
        }
        return;
      }
      case "VOTE_DELETED": {
        draftState.isFetching = false;
        draftState.items.entities.restaurants[action.restaurantId].votes.splice(
          getRestaurantById(
            { restaurants: state },
            action.restaurantId
          ).votes.indexOf(action.id),
          1
        );
        draftState.items.entities.restaurants[
          action.restaurantId
        ].all_vote_count = maybeAddToString(
          draftState.items.entities.restaurants[action.restaurantId]
            .all_vote_count,
          -1
        );
        return;
      }
      case "POSTED_NEW_TAG_TO_RESTAURANT": {
        draftState.isFetching = false;
        draftState.items.entities.restaurants[action.restaurantId].tags.push(
          action.tag.id
        );
        return;
      }
      case "POSTED_TAG_TO_RESTAURANT": {
        draftState.isFetching = false;
        if (
          state.items.entities.restaurants[action.restaurantId].tags.indexOf(
            action.id
          ) === -1
        ) {
          draftState.items.entities.restaurants[action.restaurantId].tags.push(
            action.id
          );
        }
        return;
      }
      case "DELETED_TAG_FROM_RESTAURANT": {
        draftState.isFetching = false;
        draftState.items.entities.restaurants[action.restaurantId].tags.splice(
          getRestaurantById(
            { restaurants: state },
            action.restaurantId
          ).tags.indexOf(action.id),
          1
        );
        return;
      }
      case "TAG_DELETED": {
        const { restaurants: r } = draftState.items.entities;
        if (r) {
          Object.keys(r).forEach((i) => {
            const index = Number(i);
            const changedRestaurant = r[index];
            if (changedRestaurant.tags.indexOf(action.id) > -1) {
              draftState.items.entities.restaurants[index].tags.splice(
                changedRestaurant.tags.indexOf(action.id),
                1
              );
            }
          });
        }
        return;
      }
      case "DECISION_POSTED": {
        const decision =
          draftState.items.entities.restaurants[action.decision.restaurantId];
        draftState.items.entities.restaurants[
          action.decision.restaurantId
        ].all_decision_count = maybeAddToString(decision.all_decision_count, 1);
        action.deselected.forEach((i) => {
          const r = draftState.items.entities.restaurants[i.restaurantId];
          r.all_decision_count = maybeAddToString(r.all_decision_count, -1);
        });
        return;
      }
      case "DECISIONS_DELETED": {
        action.decisions.forEach((decision) => {
          const r =
            draftState.items.entities.restaurants[decision.restaurantId];
          r.all_decision_count = maybeAddToString(r.all_decision_count, -1);
        });
        return;
      }
      case "SET_NAME_FILTER": {
        draftState.nameFilter = action.val;
        break;
      }
      default:
        break;
    }
  });

export default restaurants;
