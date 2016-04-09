import React, { PropTypes } from 'react';
import FlipMove from 'react-flip-move';
import { Element as ScrollElement } from 'react-scroll';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './RestaurantList.scss';
import RestaurantContainer from '../../containers/RestaurantContainer';

const RestaurantList = ({ items }) => (
  <ul className={s.root}>
    <FlipMove staggerDelayBy={40} staggerDurationBy={40}>
      {items.map(item => (
        <li className={s.item} key={`restaurantListItem_${item.id}`}>
          <ScrollElement name={`restaurantListItem_${item.id}`}>
            <RestaurantContainer
              id={item.id}
              name={item.name}
              address={item.address}
              votes={item.votes}
              tags={item.tags}
              shouldShowAddTagArea
              shouldShowDropdown
            />
          </ScrollElement>
        </li>
      ))}
    </FlipMove>
  </ul>
);

RestaurantList.propTypes = {
  items: PropTypes.arrayOf(PropTypes.shape({
    id: PropTypes.number.isRequired,
    name: PropTypes.string.isRequired,
    address: PropTypes.string.isRequired,
    votes: PropTypes.array.isRequired,
    tags: PropTypes.array.isRequired
  }))
};

export default withStyles(RestaurantList, s);