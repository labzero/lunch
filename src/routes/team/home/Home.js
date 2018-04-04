import PropTypes from 'prop-types';
import React, { Component } from 'react';
import { canUseDOM } from 'fbjs/lib/ExecutionEnvironment';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import FooterContainer from '../../../components/Footer/FooterContainer';
import NameFilterFormContainer from '../../../components/NameFilterForm/NameFilterFormContainer';
import PastDecisionsModalContainer from '../../../components/PastDecisionsModal/PastDecisionsModalContainer';
import RestaurantMapContainer from '../../../components/RestaurantMap/RestaurantMapContainer';
import RestaurantListContainer from '../../../components/RestaurantList/RestaurantListContainer';
import RestaurantAddFormContainer from '../../../components/RestaurantAddForm/RestaurantAddFormContainer';
import TagFilterFormContainer from '../../../components/TagFilterForm/TagFilterFormContainer';
import s from './Home.scss';

export class _Home extends Component {

  static propTypes = {
    user: PropTypes.object.isRequired,
    fetchDecisions: PropTypes.func.isRequired,
    fetchRestaurants: PropTypes.func.isRequired,
    fetchTags: PropTypes.func.isRequired,
    fetchUsers: PropTypes.func.isRequired,
    invalidateDecisions: PropTypes.func.isRequired,
    invalidateRestaurants: PropTypes.func.isRequired,
    invalidateTags: PropTypes.func.isRequired,
    invalidateUsers: PropTypes.func.isRequired,
    messageReceived: PropTypes.func.isRequired,
    pastDecisionsShown: PropTypes.bool.isRequired,
    wsPort: PropTypes.number.isRequired
  };

  componentDidMount() {
    const { messageReceived, wsPort } = this.props;

    this.props.invalidateDecisions();
    this.props.invalidateRestaurants();
    this.props.invalidateTags();
    this.props.invalidateUsers();

    if (canUseDOM) {
      let host = window.location.host;
      if (window.location.port && wsPort !== 0 && wsPort !== window.location.port) {
        host = `${window.location.hostname}:${wsPort}`;
      }
      let protocol = 'ws:';
      if (window.location.protocol === 'https:') {
        protocol = 'wss:';
      }
      this.socket = new window.RobustWebSocket(`${protocol}//${host}/api`, null, {
        shouldReconnect: (event, ws) => {
          if (event.code === 1008 || event.code === 1011) return undefined;
          return 1000 * ws.attempts;
        },
      });
      this.socket.onmessage = messageReceived;
      this.socket.onopen = this.fetchAllData;

      // avoid nginx proxy_read_timeout by sending a ping every 30 seconds
      setInterval(() => {
        this.socket.send('');
      }, 1000 * 30);
    } else {
      // websocket open will handle initial fetch
      this.fetchAllData();
    }

    setInterval(this.fetchAllData, 1000 * 60 * 60);
  }

  componentWillUnmount() {
    this.socket.close();
  }

  fetchAllData = () => {
    this.props.fetchDecisions();
    this.props.fetchRestaurants();
    this.props.fetchTags();
    this.props.fetchUsers();
  }

  render() {
    const { pastDecisionsShown, user } = this.props;

    return (
      <div className={s.root}>
        <div className={s.mapContainer}>
          <RestaurantMapContainer />
        </div>
        <div className={s.listContainer} id="listContainer">
          <section className={s.forms} id="listForms">
            {user.id && <RestaurantAddFormContainer />}
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
