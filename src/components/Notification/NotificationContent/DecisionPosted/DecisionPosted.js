import React, { PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from '../NotificationContent.scss';

const DecisionPosted = ({ loggedIn, user, restaurantName, showMapAndInfoWindow }) => {
  const restaurantEl = <b className={s.clickable} onClick={showMapAndInfoWindow}>{restaurantName}</b>;
  if (loggedIn) {
    return (
      <span>
        <b>{user}</b> marked {restaurantEl} as the decision.
      </span>
    );
  }
  return <span>{restaurantEl} was decided upon.</span>;
};

DecisionPosted.propTypes = {
  loggedIn: PropTypes.bool.isRequired,
  user: PropTypes.string,
  restaurantName: PropTypes.string.isRequired,
  showMapAndInfoWindow: PropTypes.func.isRequired
};

export default withStyles(s)(DecisionPosted);
