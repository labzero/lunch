import React, { PropTypes } from 'react';
import FlipMove from 'react-flip-move';
import { Element as ScrollElement } from 'react-scroll';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './RestaurantList.scss';
import RestaurantContainer from '../../containers/RestaurantContainer';

const RestaurantList = ({ ids }) => (
  <ul className={s.root}>
    <FlipMove staggerDelayBy={40} staggerDurationBy={40}>
      {ids.map(id => (
        <li className={s.item} key={`restaurantListItem_${id}`}>
          <ScrollElement name={`restaurantListItem_${id}`}>
            <RestaurantContainer
              id={id}
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
  ids: PropTypes.array.isRequired
};

export default withStyles(RestaurantList, s);
