import React, { Component } from "react";
import { canUseDOM } from "fbjs/lib/ExecutionEnvironment";
import RobustWebSocket from "robust-websocket";
import withStyles from "isomorphic-style-loader/withStyles";
import FooterContainer from "../../../components/Footer/FooterContainer";
import NameFilterFormContainer from "../../../components/NameFilterForm/NameFilterFormContainer";
import PastDecisionsModalContainer from "../../../components/PastDecisionsModal/PastDecisionsModalContainer";
import RestaurantMapContainer from "../../../components/RestaurantMap/RestaurantMapContainer";
import RestaurantListContainer from "../../../components/RestaurantList/RestaurantListContainer";
import RestaurantAddFormContainer from "../../../components/RestaurantAddForm/RestaurantAddFormContainer";
import TagFilterFormContainer from "../../../components/TagFilterForm/TagFilterFormContainer";
import { User } from "../../../interfaces";
import s from "./Home.scss";

export interface HomeProps {
  user?: User | null;
  fetchDecisions: () => void;
  fetchRestaurants: () => void;
  fetchTags: () => void;
  fetchUsers: () => void;
  invalidateDecisions: () => void;
  invalidateRestaurants: () => void;
  invalidateTags: () => void;
  invalidateUsers: () => void;
  messageReceived: (event: MessageEvent) => void;
  pastDecisionsShown: boolean;
  wsPort: number;
}

export class _Home extends Component<HomeProps> {
  fetchAllInterval: NodeJS.Timer;

  pingInterval: NodeJS.Timer;

  socket: RobustWebSocket;

  static defaultProps = {
    user: null,
  };

  componentDidMount() {
    const { messageReceived, wsPort } = this.props;

    this.props.invalidateDecisions();
    this.props.invalidateRestaurants();
    this.props.invalidateTags();
    this.props.invalidateUsers();

    if (canUseDOM) {
      let host = window.location.host;
      if (
        window.location.port &&
        typeof wsPort === "number" &&
        wsPort !== 0 &&
        wsPort !== Number(window.location.port)
      ) {
        host = `${window.location.hostname}:${wsPort}`;
      }
      let protocol = "ws:";
      if (window.location.protocol === "https:") {
        protocol = "wss:";
      }
      this.socket = new RobustWebSocket(`${protocol}//${host}/api`, null, {
        shouldReconnect: (event: CloseEvent, ws: RobustWebSocket) => {
          if (event.code === 1008 || event.code === 1011) return undefined;
          return Math.min(1000 * ws.attempts, 5000);
        },
      });
      this.socket.onmessage = messageReceived;
      this.socket.onopen = this.fetchAllData;

      // avoid nginx proxy_read_timeout by sending a ping every 30 seconds
      this.pingInterval = setInterval(() => {
        if (this.socket.readyState === window.WebSocket.OPEN) {
          this.socket.send("");
        }
      }, 1000 * 30);
    } else {
      // websocket open will handle initial fetch
      this.fetchAllData();
    }

    this.fetchAllInterval = setInterval(this.fetchAllData, 1000 * 60 * 60);
  }

  componentWillUnmount() {
    if (this.socket) {
      this.socket.close();
    }
    clearInterval(this.pingInterval);
    clearInterval(this.fetchAllInterval);
  }

  fetchAllData = () => {
    this.props.fetchDecisions();
    this.props.fetchRestaurants();
    this.props.fetchTags();
    this.props.fetchUsers();
  };

  render() {
    const { pastDecisionsShown, user } = this.props;

    return (
      <div className={s.root}>
        <div className={s.mapContainer}>
          <RestaurantMapContainer />
        </div>
        <div className={s.listContainer} id="listContainer">
          <section className={s.forms} id="listForms">
            {user && <RestaurantAddFormContainer />}
            <NameFilterFormContainer />
            <TagFilterFormContainer />
            <TagFilterFormContainer exclude />
          </section>
          <div className={s.restaurantList}>
            <RestaurantListContainer />
          </div>
          <FooterContainer />
        </div>
        {pastDecisionsShown && <PastDecisionsModalContainer />}
      </div>
    );
  }
}

export default withStyles(s)(_Home);
