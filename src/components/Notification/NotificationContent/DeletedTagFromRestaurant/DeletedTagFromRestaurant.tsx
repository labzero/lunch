import React from "react";
import withStyles from "isomorphic-style-loader/withStyles";
import s from "../NotificationContent.scss";
import { NotificationContentProps } from "..";

const DeletedTagFromRestaurant = ({
  loggedIn,
  user,
  restaurantName,
  tagName,
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
        <b>{user}</b> removed tag
        <b>
          &ldquo;
          {tagName}
          &rdquo;
        </b>{" "}
        from
        {restaurantEl}.
      </span>
    );
  }
  return (
    <span>
      Tag{" "}
      <b>
        &ldquo;
        {tagName}
        &rdquo;
      </b>{" "}
      was removed from {restaurantEl}.
    </span>
  );
};

DeletedTagFromRestaurant.defaultProps = {
  user: "",
};

export default withStyles(s)(DeletedTagFromRestaurant);
