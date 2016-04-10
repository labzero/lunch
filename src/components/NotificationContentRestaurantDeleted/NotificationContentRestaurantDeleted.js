import React, { PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from '../NotificationContent/NotificationContent.scss';

const NotificationContentRestaurantDeleted = ({ loggedIn, user, restaurant }) => {
  if (loggedIn) {
    return (
      <span>
        <b>{user}</b> deleted <b>{restaurant}</b>.
      </span>
    );
  }
  return <span><b>{restaurant}</b> was deleted.</span>;
};

NotificationContentRestaurantDeleted.propTypes = {
  loggedIn: PropTypes.bool.isRequired,
  user: PropTypes.string,
  restaurant: PropTypes.string.isRequired
};

export default withStyles(NotificationContentRestaurantDeleted, s);
