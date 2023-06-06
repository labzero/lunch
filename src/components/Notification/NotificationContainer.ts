import { connect } from "react-redux";
import { showMapAndInfoWindow } from "../../actions/mapUi";
import { expireNotification } from "../../actions/notifications";
import { Decision, Dispatch, Restaurant, State, Tag } from "../../interfaces";
import { getRestaurantById } from "../../selectors/restaurants";
import { getTagById } from "../../selectors/tags";
import { getUserById } from "../../selectors/users";
import Notification, { NotificationProps } from "./Notification";
import { NotificationContentProps } from "./NotificationContent";

interface OwnProps extends Pick<NotificationProps, "actionType"> {
  id: string;
  vals: {
    decision?: Decision;
    newName?: string;
    userId?: number;
    restaurant?: Restaurant;
    restaurantId?: number;
    tag?: Tag;
    tagId?: number;
  };
}

const mapStateToProps = () => {
  let contentProps: Partial<NotificationContentProps>;
  return (state: State, ownProps: OwnProps) => {
    if (contentProps === undefined) {
      const { vals } = ownProps;
      if (vals.userId === state.user?.id) {
        return { noRender: true };
      }
      let restaurantName;
      if (vals.restaurant) {
        restaurantName = vals.restaurant.name;
      } else if (vals.restaurantId) {
        const restaurant = getRestaurantById(state, vals.restaurantId);
        restaurantName = restaurant.name;
      }
      let tagName;
      if (vals.tag) {
        tagName = vals.tag.name;
      } else if (vals.tagId) {
        tagName = getTagById(state, vals.tagId).name;
      }
      contentProps = {
        decision: vals.decision,
        loggedIn: state.user !== null,
        restaurantName,
        tagName,
        newName: vals.newName,
      };
      if (contentProps.loggedIn) {
        contentProps.user = vals.userId
          ? getUserById(state, vals as { userId: number }).name
          : undefined;
      }
    }
    return {
      actionType: ownProps.actionType,
      contentProps,
    };
  };
};

const mapDispatchToProps = (dispatch: Dispatch, ownProps: OwnProps) => ({
  expireNotification: () => {
    dispatch(expireNotification(ownProps.id));
  },
  dispatch,
});

const mergeProps = (
  stateProps: ReturnType<ReturnType<typeof mapStateToProps>>,
  dispatchProps: ReturnType<typeof mapDispatchToProps>,
  ownProps: OwnProps
) => ({
  ...stateProps,
  ...dispatchProps,
  contentProps: {
    ...stateProps.contentProps,
    showMapAndInfoWindow: () => {
      dispatchProps.dispatch(showMapAndInfoWindow(ownProps.vals.restaurantId!));
    },
  },
});

export default connect(
  mapStateToProps,
  mapDispatchToProps,
  mergeProps
)(Notification);
