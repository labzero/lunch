import React from "react";
import withStyles from "isomorphic-style-loader/withStyles";
import s from "../NotificationContent.scss";
import { NotificationContentProps } from "..";

const PostedNewTagToRestaurant = ({
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
        <b>{user}</b> added new tag
        <b>
          &ldquo;
          {tagName}
          &rdquo;
        </b>{" "}
        to
        {restaurantEl}.
      </span>
    );
  }
  return (
    <span>
      New tag{" "}
      <b>
        &ldquo;
        {tagName}
        &rdquo;
      </b>{" "}
      was added to {restaurantEl}.
    </span>
  );
};

PostedNewTagToRestaurant.defaultProps = {
  user: "",
};

export default withStyles(s)(PostedNewTagToRestaurant);
