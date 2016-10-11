import React, { PropTypes } from 'react';
import EmailWhitelistItemContainer from '../../containers/EmailWhitelistItemContainer';

const EmailWhitelist = ({
  inputValue,
  whitelistEmails,
  addWhitelistEmail,
  setEmailWhitelistInputValue
}) => (
  <div>
    <form onSubmit={addWhitelistEmail}>
      <input type="email" onChange={setEmailWhitelistInputValue} value={inputValue} />
      <button disabled={inputValue === ''}>add</button>
    </form>
    <ul>
      {whitelistEmails.map(id =>
        <EmailWhitelistItemContainer id={id} key={`emailWhitelistItem_${id}`} />
      )}
    </ul>
  </div>
);

EmailWhitelist.propTypes = {
  inputValue: PropTypes.string,
  whitelistEmails: PropTypes.arrayOf(PropTypes.number).isRequired,
  addWhitelistEmail: PropTypes.func.isRequired,
  setEmailWhitelistInputValue: PropTypes.func.isRequired
};

export default EmailWhitelist;
