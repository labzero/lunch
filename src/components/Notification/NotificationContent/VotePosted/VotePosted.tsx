import React from "react";
import withStyles from "isomorphic-style-loader/withStyles";
import s from "../NotificationContent.scss";
import { NotificationContentProps } from "..";

const VotePosted = ({
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
        <b>{user}</b> voted for {restaurantEl}.
      </span>
    );
  }
  return <span>{restaurantEl} was upvoted.</span>;
};

VotePosted.defaultProps = {
  user: "",
};

export default withStyles(s)(VotePosted);
