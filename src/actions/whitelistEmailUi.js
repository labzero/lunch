import ActionTypes from '../constants/ActionTypes';

export function setEmailWhitelistInputValue(value) {
  return {
    type: ActionTypes.SET_EMAIL_WHITELIST_INPUT_VALUE,
    value
  };
}
