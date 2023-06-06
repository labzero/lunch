import React from "react";
import withStyles from "isomorphic-style-loader/withStyles";
import s from "../NotificationContent.scss";
import { NotificationContentProps } from "..";

const DecisionDeleted = ({
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
        <b>{user}</b> cancelled the decision for
        {restaurantEl}.
      </span>
    );
  }
  return (
    <span>
      The decision for
      {restaurantEl} was cancelled.
    </span>
  );
};

DecisionDeleted.defaultProps = {
  user: "",
};

export default withStyles(s)(DecisionDeleted);
