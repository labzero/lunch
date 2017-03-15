import React, { Component, PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './RestaurantsPage.scss';
import RestaurantMapContainer from '../RestaurantMap/RestaurantMapContainer';
import RestaurantListContainer from '../RestaurantList/RestaurantListContainer';
import RestaurantAddFormContainer from '../RestaurantAddForm/RestaurantAddFormContainer';
import TagFilterFormContainer from '../TagFilterForm/TagFilterFormContainer';

export class _RestaurantsPage extends Component {

  static propTypes = {
    user: PropTypes.object.isRequired,
    fetchRestaurantsIfNeeded: PropTypes.func.isRequired,
    invalidateRestaurants: PropTypes.func.isRequired
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
    let restaurantAddForm = null;
    if (typeof this.props.user.id === 'number') {
      restaurantAddForm = <RestaurantAddFormContainer />;
    }

    return (
      <div className={s.root}>
        <RestaurantMapContainer />
        <section className={s.forms}>
          {restaurantAddForm}
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

export default withStyles(s)(_RestaurantsPage);
