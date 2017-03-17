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
    fetchRestaurantsIfNeeded: PropTypes.func.isRequired,
    invalidateRestaurants: PropTypes.func.isRequired,
    teamSlug: PropTypes.string.isRequired
  };

  componentWillMount() {
    this.props.fetchRestaurantsIfNeeded();
  }

  componentDidMount() {
    setInterval(() => {
      this.props.invalidateRestaurants();
      this.props.fetchRestaurantsIfNeeded();
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
