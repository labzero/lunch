import React, { PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from '../NotificationContent.scss';

const TagDeleted = ({ loggedIn, user, tagName }) => {
  if (loggedIn) {
    return <span><b>{user}</b> deleted tag <b>"{tagName}"</b>.</span>;
  }
  return <span>Tag <b>"{tagName}"</b> was deleted.</span>;
};

TagDeleted.propTypes = {
  loggedIn: PropTypes.bool.isRequired,
  user: PropTypes.string,
  tagName: PropTypes.string.isRequired,
  showMapAndInfoWindow: PropTypes.func.isRequired
};

export default withStyles(TagDeleted, s);
