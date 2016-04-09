import React, { PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from '../NotificationContent/NotificationContent.scss';

const NotificationContentVoteDeleted = ({ loggedIn, user, restaurant, showMapAndInfoWindow }) => {
  if (loggedIn) {
    return (
      <span>
        <b>{user}</b> downvoted <b className={s.clickable} onClick={showMapAndInfoWindow}>{restaurant}</b>.
      </span>
    );
  }
  return <span><b className={s.clickable} onClick={showMapAndInfoWindow}>{restaurant}</b> was downvoted.</span>;
};

NotificationContentVoteDeleted.propTypes = {
  loggedIn: PropTypes.bool.isRequired,
  user: PropTypes.string,
  restaurant: PropTypes.string.isRequired,
  showMapAndInfoWindow: PropTypes.func.isRequired
};

export default withStyles(NotificationContentVoteDeleted, s);
