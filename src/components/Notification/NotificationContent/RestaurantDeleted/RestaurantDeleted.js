/* eslint-disable css-modules/no-unused-class */

import PropTypes from 'prop-types';
import React from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from '../NotificationContent.scss';

const RestaurantDeleted = ({ loggedIn, user, restaurantName }) => {
  if (loggedIn) {
    return (
      <span>
        <b>{user}</b>
        {' '}
deleted
        <b>{restaurantName}</b>
.
      </span>
    );
  }
  return (
    <span>
      <b>{restaurantName}</b>
      {' '}
was deleted.
    </span>
  );
};

RestaurantDeleted.propTypes = {
  loggedIn: PropTypes.bool.isRequired,
  user: PropTypes.string,
  restaurantName: PropTypes.string.isRequired
};

RestaurantDeleted.defaultProps = {
  user: ''
};

export default withStyles(s)(RestaurantDeleted);
