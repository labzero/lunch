import React, { Component, PropTypes } from 'react';
import { connect } from 'react-redux';
import fetchRestaurantsIfNeeded from '../../actions/restaurants';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './HomePage.scss';
import RestaurantList from '../RestaurantList';

const title = 'Lunch';

class HomePage extends Component {

  static contextTypes = {
    onSetTitle: PropTypes.func.isRequired
  };

  static propTypes = {
    dispatch: PropTypes.func.isRequired,
    items: PropTypes.array.isRequired
  };

  componentWillMount() {
    this.context.onSetTitle(title);
    const { dispatch } = this.props;
    dispatch(fetchRestaurantsIfNeeded());
  }

  render() {
    return (
      <div>
        <RestaurantAddForm />
        <RestaurantList items={this.props.items} />
      </div>
    );
  }

}

function mapStateToProps(state) {
  const { restaurants } = state;
  const {
    isFetching,
    lastUpdated,
    items
  } = restaurants || {
    isFetching: true,
    items: []
  };

  return {
    items,
    isFetching,
    lastUpdated
  };
}

export default connect(mapStateToProps)(withStyles(HomePage, s));
