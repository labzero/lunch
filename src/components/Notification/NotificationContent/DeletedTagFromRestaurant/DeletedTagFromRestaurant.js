import React, { PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from '../NotificationContent.scss';

const DeletedTagFromRestaurant = ({
  loggedIn,
  user,
  restaurantName,
  tagName,
  showMapAndInfoWindow
}) => {
  const restaurantEl = (
    <button className={s.clickable} onClick={showMapAndInfoWindow}>
      {restaurantName}
    </button>
  );
  if (loggedIn) {
    return (
      <span>
        <b>{user}</b> removed tag <b>&ldquo;{tagName}&rdquo;</b> from {restaurantEl}.
      </span>
    );
  }
  return (
    <span>
      Tag <b>&ldquo;{tagName}&rdquo;</b> was removed from {restaurantEl}.
    </span>
  );
};

DeletedTagFromRestaurant.propTypes = {
  loggedIn: PropTypes.bool.isRequired,
  user: PropTypes.string,
  restaurantName: PropTypes.string.isRequired,
  tagName: PropTypes.string.isRequired,
  showMapAndInfoWindow: PropTypes.func.isRequired
};

export default withStyles(s)(DeletedTagFromRestaurant);
