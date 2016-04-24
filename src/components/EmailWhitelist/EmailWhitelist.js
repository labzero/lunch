import React, { PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './EmailWhitelist.scss';
import EmailWhitelistItemContainer from '../../containers/EmailWhitelistItemContainer';

const EmailWhitelist = ({ whitelistEmails }) => (
  <div className={s.root}>
    <form>
      <input type="email" />
      <button>add</button>
    </form>
    <ul className={s.list}>
      {whitelistEmails.map(id => <EmailWhitelistItemContainer id={id} key={`emailWhitelistItem_${id}`} />)}
    </ul>
  </div>
);

EmailWhitelist.propTypes = {
  whitelistEmails: PropTypes.arrayOf(PropTypes.number).isRequired,
};

export default withStyles(EmailWhitelist, s);
