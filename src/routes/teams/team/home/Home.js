import React, { Component, PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './Home.scss';
import RestaurantMapContainer from '../../../../components/RestaurantMap/RestaurantMapContainer';
import RestaurantListContainer from '../../../../components/RestaurantList/RestaurantListContainer';
import RestaurantAddFormContainer from '../../../../components/RestaurantAddForm/RestaurantAddFormContainer';
import TagFilterFormContainer from '../../../../components/TagFilterForm/TagFilterFormContainer';

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
    teamSlug: PropTypes.string.isRequired
  };

  componentWillMount() {
    this.fetchAllData();
  }

  componentDidMount() {
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
    const { user, teamSlug } = this.props;

    return (
      <div className={s.root}>
        <RestaurantMapContainer teamSlug={teamSlug} />
        <section className={s.forms}>
          {user.id && <RestaurantAddFormContainer teamSlug={teamSlug} />}
          <TagFilterFormContainer />
          <TagFilterFormContainer exclude />
        </section>
        <div className={s.restaurantList}>
          <RestaurantListContainer teamSlug={teamSlug} />
        </div>
      </div>
    );
  }

}

export default withStyles(s)(_Home);
