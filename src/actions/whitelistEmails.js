import fetch from '../core/fetch';
import ActionTypes from '../constants/ActionTypes';
import { processResponse, credentials, jsonHeaders } from '../core/ApiClient';
import { flashError } from './flash.js';

export const deleteWhitelistEmail = id => ({
  type: ActionTypes.DELETE_WHITELIST_EMAIL,
  id
});

export const whitelistEmailDeleted = (id, userId) => ({
  type: ActionTypes.WHITELIST_EMAIL_DELETED,
  id,
  userId
});

export const postWhitelistEmail = email => ({
  type: ActionTypes.POST_WHITELIST_EMAIL,
  email
});

export const whitelistEmailPosted = (whitelistEmail, userId) => ({
  type: ActionTypes.WHITELIST_EMAIL_POSTED,
  whitelistEmail,
  userId
});

export const removeWhitelistEmail = id => dispatch => {
  dispatch(deleteWhitelistEmail(id));
  return fetch(`/api/whitelistEmails/${id}`, {
    credentials,
    method: 'delete'
  });
};

export const addWhitelistEmail = email => dispatch => {
  dispatch(postWhitelistEmail(email));
  const payload = { email };
  return fetch('/api/whitelistEmails', {
    method: 'post',
    credentials,
    headers: jsonHeaders,
    body: JSON.stringify(payload)
  })
    .then(response => processResponse(response))
    .catch(
      err => dispatch(flashError(err.message))
    );
};
