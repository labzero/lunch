import React, { PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './RestaurantList.scss';
import RestaurantListItemContainer from '../../containers/RestaurantListItemContainer';

const RestaurantList = ({ items }) => (
  <ul>
    {items.map(item => <RestaurantListItemContainer key={item.id} {...item} />)}
  </ul>
);

RestaurantList.propTypes = {
  items: PropTypes.arrayOf(PropTypes.shape({
    id: PropTypes.number.isRequired,
    name: PropTypes.string.isRequired,
    address: PropTypes.string.isRequired
  }))
};

export default withStyles(RestaurantList, s);
