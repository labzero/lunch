import ActionTypes from '../constants/ActionTypes';

export default new Map([
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
