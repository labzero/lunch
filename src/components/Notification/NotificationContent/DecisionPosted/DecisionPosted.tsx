import React from "react";
import dayjs from "dayjs";
import withStyles from "isomorphic-style-loader/withStyles";
import s from "../NotificationContent.scss";
import { NotificationContentProps } from "..";

const DecisionPosted = ({
  decision,
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
    if (dayjs().subtract(12, "hours").isAfter(decision!.createdAt)) {
      return (
        <span>
          <b>{user}</b> marked
          {restaurantEl} as a past decision.
        </span>
      );
    }
    return (
      <span>
        <b>{user}</b> marked
        {restaurantEl} as today&rsquo;s decision.
      </span>
    );
  }
  return <span>{restaurantEl} was decided upon.</span>;
};

DecisionPosted.defaultProps = {
  user: "",
};

export default withStyles(s)(DecisionPosted);
