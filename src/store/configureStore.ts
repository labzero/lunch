import { combineReducers } from "redux";
import { normalize } from "normalizr";
import { configureStore as reduxConfigureStore } from "@reduxjs/toolkit";
import * as schemas from "../schemas";
import * as reducerMaps from "../reducerMaps";
import createHelpers from "./createHelpers";
import {
  Action,
  NonNormalizedState,
  Reducer,
  State,
  StateHelpers,
} from "../interfaces";

// eslint-disable-next-line default-param-last
const generateReducer =
  <T extends keyof State>(reducer: Reducer<T>, initial: State[T]): Reducer<T> =>
  (state = initial, action: Action) => {
    return reducer(state, action);
  };

const generateReducers = <T extends keyof State>(
  newReducers: { [key in T]: Reducer<key> },
  normalizedInitialState: State
) => {
  const reducers: Partial<{ [key in T]: Reducer<key> }> = {};

  let name: T;
  for (name in newReducers) {
    reducers[name] = generateReducer<typeof name>(
      newReducers[name],
      normalizedInitialState[name]
    );
  }

  return reducers;
};

// Add the reducer to your store on the `routing` key
export default function configureStore(
  initialState: NonNormalizedState,
  helpersConfig: StateHelpers
) {
  const normalizedInitialState = JSON.parse(JSON.stringify(initialState));

  normalizedInitialState.restaurants.items = normalize(
    initialState.restaurants.items,
    [schemas.restaurant]
  );
  normalizedInitialState.tags.items = normalize(initialState.tags.items, [
    schemas.tag,
  ]);
  normalizedInitialState.teams.items = normalize(initialState.teams.items, [
    schemas.team,
  ]);
  normalizedInitialState.users.items = normalize(initialState.users.items, [
    schemas.user,
  ]);
  normalizedInitialState.restaurants.items.entities.votes =
    normalizedInitialState.restaurants.items.entities.votes || {};

  const reducers = generateReducers(reducerMaps, normalizedInitialState);

  const helpers = createHelpers(helpersConfig);

  const store = reduxConfigureStore({
    reducer: combineReducers(reducers),
    middleware: (getDefaultMiddleware) =>
      getDefaultMiddleware({
        thunk: {
          extraArgument: helpers,
        },
      }),
  });

  // Hot reload reducers (requires Webpack or Browserify HMR to be enabled)
  if (__DEV__ && module.hot) {
    module.hot.accept("../reducerMaps", () => {
      // eslint-disable-next-line global-require
      const newReducerMaps = require("../reducerMaps");
      const newReducers = generateReducers(
        newReducerMaps,
        normalizedInitialState
      );
      return store.replaceReducer(combineReducers(newReducers));
    });
  }

  return store;
}
