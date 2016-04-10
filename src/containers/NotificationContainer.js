import { connect } from 'react-redux';
import { expireNotification } from '../actions/notifications';
import { showMapAndInfoWindow } from '../actions/mapUi';
import Notification from '../components/Notification';

const mapStateToProps = (state, ownProps) => ({
  actionType: ownProps.actionType,
  contentProps: ownProps.contentProps
});

const mapDispatchToProps = (dispatch, ownProps) => ({
  expireNotification() {
    dispatch(expireNotification(ownProps.id));
  },
  dispatch
});

const mergeProps = (stateProps, dispatchProps, ownProps) => Object.assign({}, stateProps, dispatchProps, {
  contentProps: {
    ...stateProps.contentProps,
    showMapAndInfoWindow() {
      dispatchProps.dispatch(showMapAndInfoWindow(ownProps.vals.restaurantId));
    }
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps,
  mergeProps
)(Notification);
