import React from "react";
import withStyles from "isomorphic-style-loader/withStyles";
import s from "../NotificationContent.scss";
import { NotificationContentProps } from "..";

const RestaurantRenamed = ({
  loggedIn,
  user,
  restaurantName,
  newName,
  showMapAndInfoWindow,
}: NotificationContentProps) => {
  const oldNameEl = (
    <button
      className={s.clickable}
      onClick={showMapAndInfoWindow}
      type="button"
    >
      {restaurantName}
    </button>
  );
  const newNameEl = (
    <button
      className={s.clickable}
      onClick={showMapAndInfoWindow}
      type="button"
    >
      {newName}
    </button>
  );
  if (loggedIn) {
    return (
      <span>
        <b>{user}</b> renamed
        {oldNameEl} to
        {newNameEl}.
      </span>
    );
  }
  return (
    <span>
      {oldNameEl} was renamed to
      {newNameEl}.
    </span>
  );
};

RestaurantRenamed.defaultProps = {
  user: "",
};

export default withStyles(s)(RestaurantRenamed);
