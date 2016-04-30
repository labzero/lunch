import React, { PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from '../NotificationContent.scss';

const DecisionDeleted = ({ loggedIn, user }) => {
  if (loggedIn) {
    return (
      <span>
        <b>{user}</b> cancelled the decision.
      </span>
    );
  }
  return <span>The decision was cancelled.</span>;
};

DecisionDeleted.propTypes = {
  loggedIn: PropTypes.bool.isRequired,
  user: PropTypes.string
};

export default withStyles(s)(DecisionDeleted);
