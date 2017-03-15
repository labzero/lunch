import update from 'react-addons-update';
import ActionTypes from '../constants/ActionTypes';

export default new Map([
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
