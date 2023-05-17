import PropTypes from "prop-types";
import React from "react";
import { CSSTransition, TransitionGroup } from "react-transition-group";
import withStyles from "isomorphic-style-loader/withStyles";
import NotificationContainer from "../Notification/NotificationContainer";
import s from "./NotificationList.scss";

const NotificationList = ({ notifications }) => (
  <ul className={s.notifications}>
    <TransitionGroup>
      {notifications.map((notification) => (
        <CSSTransition
          classNames="notification"
          key={`notification_${notification.id}`}
          timeout={{ enter: 250, exit: 1000 }}
        >
          <li className={s.notificationContainer}>
            <NotificationContainer {...notification} />
          </li>
        </CSSTransition>
      ))}
    </TransitionGroup>
  </ul>
);

NotificationList.propTypes = {
  notifications: PropTypes.array.isRequired,
};

export default withStyles(s)(NotificationList);
