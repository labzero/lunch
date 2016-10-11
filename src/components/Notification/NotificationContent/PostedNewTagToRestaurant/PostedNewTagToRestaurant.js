import React, { PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from '../NotificationContent.scss';

const PostedNewTagToRestaurant = ({
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
        <b>{user}</b> added new tag <b>&ldquo;{tagName}&rdquo;</b> to {restaurantEl}.
      </span>
    );
  }
  return (
    <span>
      New tag <b>&ldquo;{tagName}&rdquo;</b> was added to {restaurantEl}.
    </span>
  );
};

PostedNewTagToRestaurant.propTypes = {
  loggedIn: PropTypes.bool.isRequired,
  user: PropTypes.string,
  restaurantName: PropTypes.string.isRequired,
  tagName: PropTypes.string.isRequired,
  showMapAndInfoWindow: PropTypes.func.isRequired
};

export default withStyles(s)(PostedNewTagToRestaurant);
