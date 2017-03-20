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
    invalidateDecision: PropTypes.func.isRequired,
    invalidateRestaurants: PropTypes.func.isRequired,
    invalidateTags: PropTypes.func.isRequired,
    teamSlug: PropTypes.string.isRequired
  };

  componentWillMount() {
    this.props.fetchRestaurantsIfNeeded();
    this.props.fetchTagsIfNeeded();
    this.props.fetchDecisionIfNeeded();
  }

  componentDidMount() {
    setInterval(() => {
      this.props.invalidateDecision();
      this.props.invalidateRestaurants();
      this.props.invalidateTags();
      this.props.fetchDecisionIfNeeded();
      this.props.fetchRestaurantsIfNeeded();
      this.props.fetchTagsIfNeeded();
    }, 1000 * 60 * 60 * 6);
  }

  render() {
    const { user, teamSlug } = this.props;

    let restaurantAddForm = null;
    if (typeof user.id === 'number') {
      restaurantAddForm = <RestaurantAddFormContainer teamSlug={teamSlug} />;
    }

    return (
      <div className={s.root}>
        <RestaurantMapContainer teamSlug={teamSlug} />
        <section className={s.forms}>
          {restaurantAddForm}
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
