import React, { PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from '../NotificationContent.scss';

const PostedNewTagToRestaurant = ({ loggedIn, user, restaurantName, tagName, showMapAndInfoWindow }) => {
  const restaurantEl = <b className={s.clickable} onClick={showMapAndInfoWindow}>{restaurantName}</b>;
  if (loggedIn) {
    return <span><b>{user}</b> added tag <b>"{tagName}"</b> to {restaurantEl}.</span>;
  }
  return <span>Tag <b>"{tagName}"</b> was added to {restaurantEl}.</span>;
};

PostedNewTagToRestaurant.propTypes = {
  loggedIn: PropTypes.bool.isRequired,
  user: PropTypes.string,
  restaurantName: PropTypes.string.isRequired,
  tagName: PropTypes.string.isRequired,
  showMapAndInfoWindow: PropTypes.func.isRequired
};

export default withStyles(PostedNewTagToRestaurant, s);
