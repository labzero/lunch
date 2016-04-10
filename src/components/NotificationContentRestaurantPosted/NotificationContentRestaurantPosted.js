import React, { PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from '../NotificationContent/NotificationContent.scss';

const NotificationContentRestaurantPosted = ({ loggedIn, user, restaurant, showMapAndInfoWindow }) => {
  const restaurantEl = <b className={s.clickable} onClick={showMapAndInfoWindow}>{restaurant}</b>;
  if (loggedIn) {
    return <span><b>{user}</b> added {restaurantEl}.</span>;
  }
  return <span>{restaurantEl} was added.</span>;
};

NotificationContentRestaurantPosted.propTypes = {
  loggedIn: PropTypes.bool.isRequired,
  user: PropTypes.string,
  restaurant: PropTypes.string.isRequired,
  showMapAndInfoWindow: PropTypes.func.isRequired
};

export default withStyles(NotificationContentRestaurantPosted, s);
