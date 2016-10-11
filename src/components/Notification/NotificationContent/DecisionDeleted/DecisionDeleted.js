import React, { PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from '../NotificationContent.scss';

const DecisionDeleted = ({ loggedIn, user, restaurantName, showMapAndInfoWindow }) => {
  const restaurantEl = (
    <button className={s.clickable} onClick={showMapAndInfoWindow}>
      {restaurantName}
    </button>
  );
  if (loggedIn) {
    return (
      <span>
        <b>{user}</b> cancelled the decision for {restaurantEl}.
      </span>
    );
  }
  return <span>The decision for {restaurantEl} was cancelled.</span>;
};

DecisionDeleted.propTypes = {
  loggedIn: PropTypes.bool.isRequired,
  user: PropTypes.string,
  restaurantName: PropTypes.string.isRequired,
  showMapAndInfoWindow: PropTypes.func.isRequired
};

export default withStyles(s)(DecisionDeleted);
