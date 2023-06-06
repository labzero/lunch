/* eslint-disable css-modules/no-unused-class */

import React from "react";
import withStyles from "isomorphic-style-loader/withStyles";
import s from "../NotificationContent.scss";
import { NotificationContentProps } from "..";

const TagDeleted = ({ loggedIn, user, tagName }: NotificationContentProps) => {
  if (loggedIn) {
    return (
      <span>
        <b>{user}</b> deleted tag{" "}
        <b>
          &ldquo;
          {tagName}
          &rdquo;
        </b>
        .
      </span>
    );
  }
  return (
    <span>
      Tag
      <b>
        &ldquo;
        {tagName}
        &rdquo;
      </b>{" "}
      was deleted.
    </span>
  );
};

TagDeleted.defaultProps = {
  user: "",
};

export default withStyles(s)(TagDeleted);
