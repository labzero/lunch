import React, { PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from '../NotificationContent.scss';

const VotePosted = ({ loggedIn, user, restaurantName, showMapAndInfoWindow }) => {
  const restaurantEl = (
    <b className={s.clickable} onClick={showMapAndInfoWindow}>{restaurantName}</b>
  );
  if (loggedIn) {
    return (
      <span>
        <b>{user}</b> voted for {restaurantEl}.
      </span>
    );
  }
  return <span>{restaurantEl} was upvoted.</span>;
};

VotePosted.propTypes = {
  loggedIn: PropTypes.bool.isRequired,
  user: PropTypes.string,
  restaurantName: PropTypes.string.isRequired,
  showMapAndInfoWindow: PropTypes.func.isRequired
};

export default withStyles(s)(VotePosted);
