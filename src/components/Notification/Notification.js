import React, { Component, PropTypes } from 'react';
import ActionTypes from '../../constants/ActionTypes';
import NotificationContentRestaurantPosted from '../NotificationContentRestaurantPosted';
import NotificationContentVotePosted from '../NotificationContentVotePosted';
import NotificationContentVoteDeleted from '../NotificationContentVoteDeleted';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './Notification.scss';

const contentMap = {
  [ActionTypes.RESTAURANT_POSTED]: NotificationContentRestaurantPosted,
  [ActionTypes.VOTE_POSTED]: NotificationContentVotePosted,
  [ActionTypes.VOTE_DELETED]: NotificationContentVoteDeleted
};

class Notification extends Component {

  static propTypes = {
    expireNotification: PropTypes.func.isRequired,
    noRender: PropTypes.bool,
    actionType: PropTypes.string.isRequired,
    contentProps: PropTypes.object.isRequired
  };

  componentDidMount() {
    this.timeout = setTimeout(this.props.expireNotification, 5000);
  }

  componentWillUnmount() {
    clearTimeout(this.timeout);
  }

  render() {
    if (this.props.noRender) {
      return false;
    }
    const Content = contentMap[this.props.actionType];
    return (
      <div className={s.root}>
        <button className={s.close} onClick={this.props.expireNotification}>&times;</button>
        <Content {...this.props.contentProps} />
      </div>
    );
  }

}

export default withStyles(Notification, s);