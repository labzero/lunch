import React, { Component, PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './Notification.scss';

class Notification extends Component {

  static propTypes = {
    expireNotification: PropTypes.func.isRequired,
    message: PropTypes.string,
    noRender: PropTypes.bool
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
    return (
      <div className={s.root}>
        <button className={s.close} onClick={this.props.expireNotification}>&times;</button>
        {this.props.message}
      </div>
    );
  }

}

export default withStyles(Notification, s);
