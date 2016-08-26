import { createStore, combineReducers, applyMiddleware } from 'redux';
import { routerReducer } from 'react-router-redux';
import { normalize, arrayOf } from 'normalizr';
import * as schemas from './schemas';
import thunkMiddleware from 'redux-thunk';
import * as reducerMaps from './reducerMaps';

// Add the reducer to your store on the `routing` key
export default function configureStore(initialState) {
  const generateReducer = (map, initial) => (state = initial, action) => {
    const reducer = map.get(action.type);
    if (reducer === undefined) {
      return state;
    }

    return reducer(state, action);
  };

  const normalizedInitialState = Object.assign({}, initialState);

  normalizedInitialState.restaurants.items =
    normalize(initialState.restaurants.items, arrayOf(schemas.restaurant));
  normalizedInitialState.tags.items =
    normalize(initialState.tags.items, arrayOf(schemas.tag));
  normalizedInitialState.users.items =
    normalize(initialState.users.items, arrayOf(schemas.user));
  normalizedInitialState.whitelistEmails.items =
    normalize(initialState.whitelistEmails.items, arrayOf(schemas.whitelistEmail));
  normalizedInitialState.restaurants.items.entities.votes =
    initialState.restaurants.items.entities.votes || {};

  const reducers = {};

  Object.keys(reducerMaps).forEach(name => {
    if (reducerMaps.hasOwnProperty(name)) {
      reducers[name] = generateReducer(reducerMaps[name], normalizedInitialState[name] || {});
    }
  });

  return createStore(
    combineReducers({
      ...reducers,
      routing: routerReducer
    }),
    normalizedInitialState,
    applyMiddleware(thunkMiddleware)
  );
}
