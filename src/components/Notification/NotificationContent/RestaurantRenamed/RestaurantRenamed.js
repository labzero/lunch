import PropTypes from 'prop-types';
import React from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from '../NotificationContent.scss';

const RestaurantRenamed = ({
  loggedIn, user, restaurantName, newName, showMapAndInfoWindow
}) => {
  const oldNameEl = (
    <button className={s.clickable} onClick={showMapAndInfoWindow} type="button">{restaurantName}</button>
  );
  const newNameEl = (
    <button className={s.clickable} onClick={showMapAndInfoWindow} type="button">{newName}</button>
  );
  if (loggedIn) {
    return (
      <span>
        <b>{user}</b>
        {' '}
renamed
        {oldNameEl}
        {' '}
to
        {newNameEl}
.
      </span>
    );
  }
  return (
    <span>
      {oldNameEl}
      {' '}
was renamed to
      {' '}
      {newNameEl}
.
    </span>
  );
};

RestaurantRenamed.propTypes = {
  loggedIn: PropTypes.bool.isRequired,
  user: PropTypes.string,
  restaurantName: PropTypes.string.isRequired,
  newName: PropTypes.string.isRequired,
  showMapAndInfoWindow: PropTypes.func.isRequired
};

RestaurantRenamed.defaultProps = {
  user: ''
};

export default withStyles(s)(RestaurantRenamed);
