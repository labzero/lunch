import React, { PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from '../NotificationContent.scss';

const PostedTagToRestaurant = ({
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
    return <span><b>{user}</b> added tag <b>&ldquo;{tagName}&rdquo;</b> to {restaurantEl}.</span>;
  }
  return <span>Tag <b>&ldquo;{tagName}&rdquo;</b> was added to {restaurantEl}.</span>;
};

PostedTagToRestaurant.propTypes = {
  loggedIn: PropTypes.bool.isRequired,
  user: PropTypes.string,
  restaurantName: PropTypes.string.isRequired,
  tagName: PropTypes.string.isRequired,
  showMapAndInfoWindow: PropTypes.func.isRequired
};

export default withStyles(s)(PostedTagToRestaurant);
