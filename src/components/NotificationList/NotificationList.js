import React, { PropTypes } from 'react';
import ReactCSSTransitionGroup from 'react-addons-css-transition-group';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import NotificationContainer from '../../containers/NotificationContainer';
import s from './NotificationList.scss';

const NotificationList = ({ notifications }) => (
  <ul className={s.notifications}>
    <ReactCSSTransitionGroup
      transitionName="notification"
      transitionEnterTimeout={250}
      transitionLeaveTimeout={1000}
    >
      {notifications.map(notification =>
        <li className={s.notificationContainer} key={`notification_${notification.id}`}>
          <NotificationContainer {...notification} />
        </li>
      )}
    </ReactCSSTransitionGroup>
  </ul>
);

NotificationList.propTypes = {
  notifications: PropTypes.array.isRequired
};

export default withStyles(s)(NotificationList);
