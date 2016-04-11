import { connect } from 'react-redux';
import { expireNotification } from '../actions/notifications';
import { showMapAndInfoWindow } from '../actions/mapUi';
import Notification from '../components/Notification';

const mapStateToProps = () => {
  let contentProps;
  return (state, ownProps) => {
    if (contentProps === undefined) {
      const { vals } = ownProps;
      if (vals.userId === state.user.id) {
        return { noRender: true };
      }
      let restaurantName;
      if (vals.restaurant) {
        restaurantName = vals.restaurant.name;
      } else if (vals.restaurantId) {
        restaurantName = state.restaurants.items.find(r => r.id === vals.restaurantId).name;
      }
      let tagName;
      if (vals.tag) {
        tagName = vals.tag.name;
      } else if (vals.tagId) {
        tagName = state.tags.items.find(t => t.id === vals.tagId).name;
      }
      contentProps = {
        loggedIn: state.user.id !== undefined,
        restaurantName,
        tagName,
        newName: vals.newName
      };
      if (contentProps.loggedIn) {
        contentProps.user = vals.userId ? state.users.items.find(u => u.id === vals.userId).name : undefined;
      }
    }
    return {
      actionType: ownProps.actionType,
      contentProps
    };
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
