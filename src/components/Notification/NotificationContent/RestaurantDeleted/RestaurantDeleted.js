import React, { PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from '../NotificationContent.scss';

const RestaurantDeleted = ({ loggedIn, user, restaurantName }) => {
  if (loggedIn) {
    return (
      <span>
        <b>{user}</b> deleted <b>{restaurantName}</b>.
      </span>
    );
  }
  return <span><b>{restaurantName}</b> was deleted.</span>;
};

RestaurantDeleted.propTypes = {
  loggedIn: PropTypes.bool.isRequired,
  user: PropTypes.string,
  restaurantName: PropTypes.string.isRequired
};

export default withStyles(RestaurantDeleted, s);
