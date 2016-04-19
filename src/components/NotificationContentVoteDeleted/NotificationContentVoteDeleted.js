import React, { PropTypes } from 'react';

const NotificationContentVoteDeleted = ({ loggedIn, user, restaurant }) => {
  if (loggedIn) {
    return <span>{user} downvoted {restaurant}.</span>;
  }
  return <span>{restaurant} was downvoted.</span>;
};

NotificationContentVoteDeleted.propTypes = {
  loggedIn: PropTypes.bool.isRequired,
  user: PropTypes.string,
  restaurant: PropTypes.string.isRequired
};

export default NotificationContentVoteDeleted;
