import React, { PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './EmailWhitelist.scss';
import EmailWhitelistItemContainer from '../../containers/EmailWhitelistItemContainer';

const EmailWhitelist = ({ inputValue, whitelistEmails, addWhitelistEmail, setEmailWhitelistInputValue }) => (
  <div className={s.root}>
    <form onSubmit={addWhitelistEmail}>
      <input type="email" onChange={setEmailWhitelistInputValue} value={inputValue} />
      <button disabled={inputValue === ''}>add</button>
    </form>
    <ul className={s.list}>
      {whitelistEmails.map(id => <EmailWhitelistItemContainer id={id} key={`emailWhitelistItem_${id}`} />)}
    </ul>
  </div>
);

EmailWhitelist.propTypes = {
  inputValue: PropTypes.string,
  whitelistEmails: PropTypes.arrayOf(PropTypes.number).isRequired,
  addWhitelistEmail: PropTypes.func.isRequired,
  setEmailWhitelistInputValue: PropTypes.func.isRequired
};

export default withStyles(EmailWhitelist, s);
