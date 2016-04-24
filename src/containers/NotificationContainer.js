import { connect } from 'react-redux';
import { getRestaurantById } from '../selectors/restaurants';
import { getTagById } from '../selectors/tags';
import { getUserById } from '../selectors/users';
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
      let latLng;
      if (vals.restaurant) {
        restaurantName = vals.restaurant.name;
        latLng = vals.restaurant.latLng;
      } else if (vals.restaurantId) {
        const restaurant = getRestaurantById(state, vals.restaurantId);
        restaurantName = restaurant.name;
        latLng = {
          lat: restaurant.lat,
          lng: restaurant.lng
        };
      }
      let tagName;
      if (vals.tag) {
        tagName = vals.tag.name;
      } else if (vals.tagId) {
        tagName = getTagById(state, vals).name;
      }
      contentProps = {
        loggedIn: state.user.id !== undefined,
        restaurantName,
        latLng,
        tagName,
        newName: vals.newName
      };
      if (contentProps.loggedIn) {
        contentProps.user = vals.userId ? getUserById(state, vals).name : undefined;
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
      dispatchProps.dispatch(showMapAndInfoWindow(ownProps.vals.restaurantId, stateProps.contentProps.latLng));
    }
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps,
  mergeProps
)(Notification);
