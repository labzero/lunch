import { connect } from "react-redux";
import { State } from "../../interfaces";
import NotificationList from "./NotificationList";

const mapStateToProps = (state: State) => ({
  notifications: state.notifications,
});

export default connect(mapStateToProps)(NotificationList);
