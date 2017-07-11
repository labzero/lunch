import PropTypes from 'prop-types';
import React, { Component } from 'react';
import { canUseDOM } from 'fbjs/lib/ExecutionEnvironment';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import RestaurantMapContainer from '../../../components/RestaurantMap/RestaurantMapContainer';
import RestaurantListContainer from '../../../components/RestaurantList/RestaurantListContainer';
import RestaurantAddFormContainer from '../../../components/RestaurantAddForm/RestaurantAddFormContainer';
import TagFilterFormContainer from '../../../components/TagFilterForm/TagFilterFormContainer';
import s from './Home.scss';

export class _Home extends Component {

  static propTypes = {
    user: PropTypes.object.isRequired,
    fetchDecisionIfNeeded: PropTypes.func.isRequired,
    fetchRestaurantsIfNeeded: PropTypes.func.isRequired,
    fetchTagsIfNeeded: PropTypes.func.isRequired,
    fetchUsersIfNeeded: PropTypes.func.isRequired,
    invalidateDecision: PropTypes.func.isRequired,
    invalidateRestaurants: PropTypes.func.isRequired,
    invalidateTags: PropTypes.func.isRequired,
    invalidateUsers: PropTypes.func.isRequired,
    messageReceived: PropTypes.func.isRequired,
    wsPort: PropTypes.number.isRequired
  };

  componentDidMount() {
    const { messageReceived, wsPort } = this.props;

    this.fetchAllData();

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
    }

    setInterval(() => {
      this.props.invalidateDecision();
      this.props.invalidateRestaurants();
      this.props.invalidateTags();
      this.props.invalidateUsers();
      this.fetchAllData();
    }, 1000 * 60 * 60 * 6);
  }

  fetchAllData() {
    this.props.fetchDecisionIfNeeded();
    this.props.fetchRestaurantsIfNeeded();
    this.props.fetchTagsIfNeeded();
    this.props.fetchUsersIfNeeded();
  }

  render() {
    const { user } = this.props;

    return (
      <div className={s.root}>
        <RestaurantMapContainer />
        <section className={s.forms}>
          {user.id && <RestaurantAddFormContainer />}
          <TagFilterFormContainer />
          <TagFilterFormContainer exclude />
        </section>
        <div className={s.restaurantList}>
          <RestaurantListContainer />
        </div>
      </div>
    );
  }

}

export default withStyles(s)(_Home);
