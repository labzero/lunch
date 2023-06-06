import { connect } from "react-redux";
import {
  fetchDecisions,
  invalidateDecisions,
} from "../../../actions/decisions";
import {
  fetchRestaurants,
  invalidateRestaurants,
} from "../../../actions/restaurants";
import { fetchTags, invalidateTags } from "../../../actions/tags";
import { fetchUsers, invalidateUsers } from "../../../actions/users";
import { messageReceived } from "../../../actions/websockets";
import Home from "./Home";
import { Dispatch, State } from "../../../interfaces";

const mapStateToProps = (state: State) => ({
  pastDecisionsShown: !!state.modals.pastDecisions,
  user: state.user,
  wsPort: state.wsPort,
});

const mapDispatchToProps = (dispatch: Dispatch) => ({
  fetchDecisions() {
    dispatch(fetchDecisions());
  },
  fetchRestaurants() {
    dispatch(fetchRestaurants());
  },
  fetchTags() {
    dispatch(fetchTags());
  },
  fetchUsers() {
    dispatch(fetchUsers());
  },
  invalidateDecisions() {
    dispatch(invalidateDecisions());
  },
  invalidateRestaurants() {
    dispatch(invalidateRestaurants());
  },
  invalidateTags() {
    dispatch(invalidateTags());
  },
  invalidateUsers() {
    dispatch(invalidateUsers());
  },
  messageReceived(event: MessageEvent) {
    dispatch(messageReceived(event.data));
  },
});

export default connect(mapStateToProps, mapDispatchToProps)(Home);
