import React, { PropTypes } from 'react';
import CSSTransitionGroup from 'react-transition-group/CSSTransitionGroup';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import NotificationContainer from '../Notification/NotificationContainer';
import s from './NotificationList.scss';

const NotificationList = ({ notifications }) => (
  <ul className={s.notifications}>
    <CSSTransitionGroup
      transitionName="notification"
      transitionEnterTimeout={250}
      transitionLeaveTimeout={1000}
    >
      {notifications.map(notification =>
        <li className={s.notificationContainer} key={`notification_${notification.id}`}>
          <NotificationContainer {...notification} />
        </li>
      )}
    </CSSTransitionGroup>
  </ul>
);

NotificationList.propTypes = {
  notifications: PropTypes.array.isRequired
};

export default withStyles(s)(NotificationList);
