export const getWhitelistEmailIds = state => state.whitelistEmails.items.result;
export const getWhitelistEmailEntities = state => state.whitelistEmails.items.entities.whitelistEmails;
export const getWhitelistEmailById = (state, props) =>
  getWhitelistEmailEntities(state)[typeof props === 'object' ? props.whitelistEmailId : props];
