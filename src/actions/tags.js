import fetch from '../core/fetch';
import ActionTypes from '../constants/ActionTypes';

/* This doesn't work yet. */

export function addNewTagToRestaurant(value) {
  return (dispatch) => {
    dispatch(postTag(value));
    return fetch(`/api/restaurants/${id}/votes`, {
      method: 'post',
      credentials: 'same-origin'
    })
      .then(response => processResponse(response))
      .catch(
        err => dispatch(flashError(err.message))
      );
  };
}
