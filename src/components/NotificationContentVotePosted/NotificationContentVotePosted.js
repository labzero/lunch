import React, { PropTypes } from 'react';

const NotificationContentVotePosted = ({ loggedIn, user, restaurant }) => {
  if (loggedIn) {
    return <span>{user} voted for {restaurant}.</span>;
  }
  return <span>{restaurant} was upvoted.</span>;
};

NotificationContentVotePosted.propTypes = {
  loggedIn: PropTypes.bool.isRequired,
  user: PropTypes.string,
  restaurant: PropTypes.string.isRequired
};

export default NotificationContentVotePosted;
