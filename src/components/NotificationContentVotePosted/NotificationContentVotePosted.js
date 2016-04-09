import React, { PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from '../NotificationContent/NotificationContent.scss';

const NotificationContentVotePosted = ({ loggedIn, user, restaurant, showMapAndInfoWindow }) => {
  if (loggedIn) {
    return (
      <span>
        <b>{user}</b> voted for <b className={s.clickable} onClick={showMapAndInfoWindow}>{restaurant}</b>.
      </span>
    );
  }
  return <span><b className={s.clickable} onClick={showMapAndInfoWindow}>{restaurant}</b> was upvoted.</span>;
};

NotificationContentVotePosted.propTypes = {
  loggedIn: PropTypes.bool.isRequired,
  user: PropTypes.string,
  restaurant: PropTypes.string.isRequired,
  showMapAndInfoWindow: PropTypes.func.isRequired
};

export default withStyles(NotificationContentVotePosted, s);
