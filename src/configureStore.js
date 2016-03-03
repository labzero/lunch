import { createStore, combineReducers, applyMiddleware } from 'redux';
import { routerReducer } from 'react-router-redux';
import thunkMiddleware from 'redux-thunk';
import { restaurants, user } from './reducers';

// Add the reducer to your store on the `routing` key
export default (initialState) => createStore(
  combineReducers({
    user,
    restaurants,
    routing: routerReducer
  }),
  initialState,
  applyMiddleware(thunkMiddleware)
);
