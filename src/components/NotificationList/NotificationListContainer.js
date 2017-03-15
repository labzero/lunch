import { connect } from 'react-redux';
import NotificationList from './NotificationList';

const mapStateToProps = state => ({
  notifications: state.notifications
});

export default connect(
  mapStateToProps
)(NotificationList);
