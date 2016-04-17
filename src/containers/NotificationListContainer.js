import { connect } from 'react-redux';
import NotificationList from '../components/NotificationList';

const mapStateToProps = state => ({
  notifications: state.notifications
});

export default connect(
  mapStateToProps
)(NotificationList);
