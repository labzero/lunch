import { createStore, combineReducers, applyMiddleware } from 'redux';
import { routerReducer } from 'react-router-redux';
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

  const reducers = {};

  for (const name in reducerMaps) {
    if (reducerMaps.hasOwnProperty(name)) {
      reducers[name] = generateReducer(reducerMaps[name], initialState[name] || {});
    }
  }

  return createStore(
    combineReducers({
      ...reducers,
      routing: routerReducer
    }),
    initialState,
    applyMiddleware(thunkMiddleware)
  );
}
