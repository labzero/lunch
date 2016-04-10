import { createStore, combineReducers, applyMiddleware } from 'redux';
import { routerReducer } from 'react-router-redux';
import thunkMiddleware from 'redux-thunk';
import base, * as reducerMaps from './reducerMaps';

// Add the reducer to your store on the `routing` key
export default function configureStore(initialState) {
  const generateReducer = (map, initial) => (state = initial, action) => {
    const reducer = map[action.type];
    if (reducer === undefined) {
      return state;
    }

    return reducer(state, action);
  };

  const reducers = {};

  for (const name in reducerMaps) {
    if (reducerMaps.hasOwnProperty(name) && name !== 'default') {
      reducers[name] = generateReducer(reducerMaps[name], initialState[name] || {});
    }
  }

  const combinedReducers = combineReducers({
    ...reducers,
    routing: routerReducer
  });

  const baseReducer = generateReducer(base, initialState);

  const wrappedCombinedReducers = (state, action) =>
    combinedReducers(baseReducer(state, action), action);

  return createStore(
    wrappedCombinedReducers,
    initialState,
    applyMiddleware(thunkMiddleware)
  );
}
