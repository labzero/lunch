import React, { PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './RestaurantList.scss';
import RestaurantContainer from '../../containers/RestaurantContainer';

const RestaurantList = ({ items }) => (
  <ul className={s.root}>
    {items.map(item => (
      <li className={s.item} key={item.id}>
        <RestaurantContainer
          id={item.id}
          name={item.name}
          address={item.address}
          votes={item.votes}
          tags={item.tags}
          isAddingTags={item.isAddingTags}
        />
      </li>
    ))}
  </ul>
);

RestaurantList.propTypes = {
  items: PropTypes.arrayOf(PropTypes.shape({
    id: PropTypes.number.isRequired,
    name: PropTypes.string.isRequired,
    address: PropTypes.string.isRequired,
    votes: PropTypes.array.isRequired,
    tags: PropTypes.array.isRequired,
    isAddingTags: PropTypes.bool
  }))
};

export default withStyles(RestaurantList, s);
