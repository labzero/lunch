import React, { Component } from "react";
import RobustWebSocket from "robust-websocket";
import withStyles from "isomorphic-style-loader/withStyles";
import FooterContainer from "../../../components/Footer/FooterContainer";
import NameFilterFormContainer from "../../../components/NameFilterForm/NameFilterFormContainer";
import PastDecisionsModalContainer from "../../../components/PastDecisionsModal/PastDecisionsModalContainer";
import RestaurantMapContainer from "../../../components/RestaurantMap/RestaurantMapContainer";
import RestaurantListContainer from "../../../components/RestaurantList/RestaurantListContainer";
import RestaurantAddFormContainer from "../../../components/RestaurantAddForm/RestaurantAddFormContainer";
import TagFilterFormContainer from "../../../components/TagFilterForm/TagFilterFormContainer";
import canUseDOM from "../../../helpers/canUseDOM";
import { User } from "../../../interfaces";
import s from "./Home.scss";
import GoogleMapsLoaderContext, {
  IGoogleMapsLoaderContext,
} from "../../../components/GoogleMapsLoaderContext/GoogleMapsLoaderContext";

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
  port: number;
}

export class _Home extends Component<HomeProps> {
  static contextType = GoogleMapsLoaderContext;

  fetchAllInterval: NodeJS.Timeout;

  pingInterval: NodeJS.Timeout;

  socket: RobustWebSocket;

  static defaultProps = {
    user: null,
  };

  constructor(props: HomeProps, context: IGoogleMapsLoaderContext) {
    super(props);

    if (canUseDOM) {
      const { loader } = context;
      loader?.load();
    }
  }

  componentDidMount() {
    const { messageReceived, port } = this.props;

    this.props.invalidateDecisions();
    this.props.invalidateRestaurants();
    this.props.invalidateTags();
    this.props.invalidateUsers();

    if (canUseDOM) {
      let host = window.location.host;
      if (
        window.location.port &&
        typeof port === "number" &&
        port !== 0 &&
        port !== Number(window.location.port)
      ) {
        host = `${window.location.hostname}:${port}`;
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
