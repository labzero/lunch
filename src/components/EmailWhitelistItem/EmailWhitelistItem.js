import React, { PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './EmailWhitelistItem.scss';

const EmailWhitelistItem = ({ whitelistEmail, handleDeleteClicked }) => (
  <li>
    <span className={s.tagContainer}>
      {whitelistEmail.email}
      <button onClick={handleDeleteClicked}>&times;</button>
    </span>
  </li>
);

EmailWhitelistItem.propTypes = {
  whitelistEmail: PropTypes.object.isRequired,
  handleDeleteClicked: PropTypes.func.isRequired
};

export default withStyles(s)(EmailWhitelistItem);
