import React, { Component, PropTypes } from 'react';
import ActionTypes from '../../constants/ActionTypes';
import NotificationContentVotePosted from '../NotificationContentVotePosted';
import NotificationContentVoteDeleted from '../NotificationContentVoteDeleted';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './Notification.scss';

class Notification extends Component {

  static propTypes = {
    expireNotification: PropTypes.func.isRequired,
    noRender: PropTypes.bool,
    actionType: PropTypes.string.isRequired,
    dict: PropTypes.object.isRequired
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
    let content;
    switch (this.props.actionType) {
      case ActionTypes.VOTE_POSTED: {
        content = <NotificationContentVotePosted {...this.props.dict} />;
        break;
      }
      case ActionTypes.VOTE_DELETED: {
        content = <NotificationContentVoteDeleted {...this.props.dict} />;
        break;
      }
      default: break;
    }
    return (
      <div className={s.root}>
        <button className={s.close} onClick={this.props.expireNotification}>&times;</button>
        {content}
      </div>
    );
  }

}

export default withStyles(Notification, s);
