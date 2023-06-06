import React from "react";
import withStyles from "isomorphic-style-loader/withStyles";
import s from "../NotificationContent.scss";
import { NotificationContentProps } from "..";

const RestaurantPosted = ({
  loggedIn,
  user,
  restaurantName,
  showMapAndInfoWindow,
}: NotificationContentProps) => {
  const restaurantEl = (
    <button
      className={s.clickable}
      onClick={showMapAndInfoWindow}
      type="button"
    >
      {restaurantName}
    </button>
  );
  if (loggedIn) {
    return (
      <span>
        <b>{user}</b> added
        {restaurantEl}.
      </span>
    );
  }
  return <span>{restaurantEl} was added.</span>;
};

RestaurantPosted.defaultProps = {
  user: "",
};

export default withStyles(s)(RestaurantPosted);
