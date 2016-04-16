import React, { PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from '../NotificationContent.scss';

const RestaurantRenamed = ({ loggedIn, user, restaurantName, newName, showMapAndInfoWindow }) => {
  const oldNameEl = <b className={s.clickable} onClick={showMapAndInfoWindow}>{restaurantName}</b>;
  const newNameEl = <b className={s.clickable} onClick={showMapAndInfoWindow}>{newName}</b>;
  if (loggedIn) {
    return (
      <span>
        <b>{user}</b> renamed {oldNameEl} to {newNameEl}.
      </span>
    );
  }
  return <span>{oldNameEl} was renamed to {newNameEl}.</span>;
};

RestaurantRenamed.propTypes = {
  loggedIn: PropTypes.bool.isRequired,
  user: PropTypes.string,
  restaurantName: PropTypes.string.isRequired,
  newName: PropTypes.string.isRequired,
  showMapAndInfoWindow: PropTypes.func.isRequired
};

export default withStyles(s)(RestaurantRenamed);
