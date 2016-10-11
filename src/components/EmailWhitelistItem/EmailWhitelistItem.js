import React, { PropTypes } from 'react';

const EmailWhitelistItem = ({ whitelistEmail, handleDeleteClicked }) => (
  <li>
    <span>
      {whitelistEmail.email}
      <button onClick={handleDeleteClicked}>&times;</button>
    </span>
  </li>
);

EmailWhitelistItem.propTypes = {
  whitelistEmail: PropTypes.object.isRequired,
  handleDeleteClicked: PropTypes.func.isRequired
};

export default EmailWhitelistItem;
