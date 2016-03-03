import React, { Component, PropTypes } from 'react';
import { fetchRestaurantsIfNeeded } from '../../actions/restaurants';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './HomePage.scss';
import RestaurantListContainer from '../../containers/RestaurantListContainer';
import RestaurantAddFormContainer from '../../containers/RestaurantAddFormContainer';

const title = 'Lunch';

class HomePage extends Component {

  static contextTypes = {
    onSetTitle: PropTypes.func.isRequired
  };

  static propTypes = {
    dispatch: PropTypes.func.isRequired,
    user: PropTypes.object.isRequired
  };

  componentWillMount() {
    this.context.onSetTitle(title);
    const { dispatch } = this.props;
    dispatch(fetchRestaurantsIfNeeded());
  }

  render() {
    let form = null;
    if (typeof this.props.user.id === 'number') {
      form = <RestaurantAddFormContainer />;
    }

    return (
      <div>
        {form}
        <RestaurantListContainer />
      </div>
    );
  }

}

export default withStyles(HomePage, s);
