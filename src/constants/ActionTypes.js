/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-2016 Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

const actions = [
  'INVALIDATE_RESTAURANTS',
  'POST_RESTAURANT',
  'RESTAURANT_POSTED',
  'DELETE_RESTAURANT',
  'RESTAURANT_DELETED',
  'REQUEST_RESTAURANTS',
  'RECEIVE_RESTAURANTS',
  'FLASH_ERROR',
  'EXPIRE_FLASH',
  'POST_VOTE',
  'VOTE_POSTED',
  'DELETE_VOTE',
  'VOTE_DELETED',
  'SHOW_INFO_WINDOW',
  'HIDE_INFO_WINDOW',
  'SHOW_ADD_TAG_FORM',
  'HIDE_ADD_TAG_FORM',
  'SET_ADD_TAG_AUTOSUGGEST_VALUE',
  'POST_NEW_TAG_TO_RESTAURANT',
  'POSTED_NEW_TAG_TO_RESTAURANT',
  'POST_TAG_TO_RESTAURANT',
  'POSTED_TAG_TO_RESTAURANT',
  'DELETE_TAG_FROM_RESTAURANT',
  'DELETED_TAG_FROM_RESTAURANT',
  'SHOW_MODAL',
  'HIDE_MODAL',
  'DELETE_TAG',
  'TAG_DELETED'
];

const actionMap = {};

actions.forEach(action => {
  actionMap[action] = action;
});

export default actionMap;
