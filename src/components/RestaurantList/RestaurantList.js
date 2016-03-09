import React, { PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './RestaurantList.scss';
import RestaurantContainer from '../../containers/RestaurantContainer';

const RestaurantList = ({ items }) => (
  <ul className={s.root}>
    {items.map(item => <li className={s.item}><RestaurantContainer key={item.id} {...item} /></li>)}
  </ul>
);

RestaurantList.propTypes = {
  items: PropTypes.arrayOf(PropTypes.shape({
    id: PropTypes.number.isRequired,
    name: PropTypes.string.isRequired,
    address: PropTypes.string.isRequired,
    votes: PropTypes.array.isRequired
  }))
};

export default withStyles(RestaurantList, s);
