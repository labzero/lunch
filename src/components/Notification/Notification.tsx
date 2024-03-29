import PropTypes from "prop-types";
import React, { Component, FC } from "react";
import withStyles from "isomorphic-style-loader/withStyles";
import RestaurantPosted from "./NotificationContent/RestaurantPosted/RestaurantPosted";
import RestaurantDeleted from "./NotificationContent/RestaurantDeleted/RestaurantDeleted";
import RestaurantRenamed from "./NotificationContent/RestaurantRenamed/RestaurantRenamed";
import VotePosted from "./NotificationContent/VotePosted/VotePosted";
import VoteDeleted from "./NotificationContent/VoteDeleted/VoteDeleted";
import PostedNewTagToRestaurant from "./NotificationContent/PostedNewTagToRestaurant/PostedNewTagToRestaurant";
import PostedTagToRestaurant from "./NotificationContent/PostedTagToRestaurant/PostedTagToRestaurant";
import DeletedTagFromRestaurant from "./NotificationContent/DeletedTagFromRestaurant/DeletedTagFromRestaurant";
import TagDeleted from "./NotificationContent/TagDeleted/TagDeleted";
import DecisionPosted from "./NotificationContent/DecisionPosted/DecisionPosted";
import DecisionDeleted from "./NotificationContent/DecisionDeleted/DecisionDeleted";
import s from "./Notification.scss";
import { NotificationContentProps } from "./NotificationContent";

const contentMap: { [key: string]: FC<NotificationContentProps> } = {
  RESTAURANT_POSTED: RestaurantPosted,
  RESTAURANT_DELETED: RestaurantDeleted,
  RESTAURANT_RENAMED: RestaurantRenamed,
  VOTE_POSTED: VotePosted,
  VOTE_DELETED: VoteDeleted,
  POSTED_NEW_TAG_TO_RESTAURANT: PostedNewTagToRestaurant,
  POSTED_TAG_TO_RESTAURANT: PostedTagToRestaurant,
  DELETED_TAG_FROM_RESTAURANT: DeletedTagFromRestaurant,
  TAG_DELETED: TagDeleted,
  DECISION_POSTED: DecisionPosted,
  DECISIONS_DELETED: DecisionDeleted,
};

export interface NotificationProps {
  expireNotification: () => void;
  noRender?: boolean;
  actionType: keyof typeof contentMap;
  contentProps: NotificationContentProps;
}

class Notification extends Component<NotificationProps> {
  timeout: NodeJS.Timeout;

  static propTypes = {
    expireNotification: PropTypes.func.isRequired,
    noRender: PropTypes.bool,
    actionType: PropTypes.string,
    contentProps: PropTypes.object.isRequired,
  };

  static defaultProps = {
    actionType: "",
    noRender: false,
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
        <button
          className={s.close}
          onClick={this.props.expireNotification}
          type="button"
        >
          &times;
        </button>
        <Content {...this.props.contentProps} />
      </div>
    );
  }
}

export default withStyles(s)(Notification);
