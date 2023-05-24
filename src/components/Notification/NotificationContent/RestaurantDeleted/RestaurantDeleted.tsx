/* eslint-disable css-modules/no-unused-class */

import React from "react";
import withStyles from "isomorphic-style-loader/withStyles";
import s from "../NotificationContent.scss";
import { NotificationContentProps } from "..";

const RestaurantDeleted = ({
  loggedIn,
  user,
  restaurantName,
}: NotificationContentProps) => {
  if (loggedIn) {
    return (
      <span>
        <b>{user}</b> deleted
        <b>{restaurantName}</b>.
      </span>
    );
  }
  return (
    <span>
      <b>{restaurantName}</b> was deleted.
    </span>
  );
};

RestaurantDeleted.defaultProps = {
  user: "",
};

export default withStyles(s)(RestaurantDeleted);
