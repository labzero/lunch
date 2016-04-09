import { connect } from 'react-redux';
import { expireNotification } from '../actions/notifications';
import { showMapAndInfoWindow } from '../actions/mapUi';
import Notification from '../components/Notification';

const mapStateToProps = (state, ownProps) => {
  const { vals } = ownProps;
  if (vals.userId === state.user.id) {
    return { noRender: true };
  }
  const contentProps = {
    loggedIn: state.user.id !== undefined,
    restaurant: vals.restaurantId ? state.restaurants.items.find(r => r.id === vals.restaurantId).name : undefined
  };
  if (contentProps.loggedIn) {
    contentProps.user = vals.userId ? state.users.items.find(u => u.id === vals.userId).name : undefined;
  }
  return {
    actionType: ownProps.actionType,
    contentProps
  };
};

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
