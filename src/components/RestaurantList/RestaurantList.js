import React, { Component, PropTypes } from 'react';
import FlipMove from 'react-flip-move';
import { Element as ScrollElement } from 'react-scroll';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './RestaurantList.scss';
import RestaurantContainer from '../Restaurant/RestaurantContainer';

class RestaurantList extends Component {
  componentWillUpdate() {
    this.scrollY = window.scrollY;
  }

  componentDidUpdate() {
    // prevent Chrome from scrolling to new position of voted restaurant
    window.scrollTo(0, this.scrollY);
  }

  render() {
    const { ids, restaurantListReady, teamSlug } = this.props;

    if (!restaurantListReady) {
      return null;
    }

    return (
      <FlipMove typeName="ul" className={s.root} staggerDelayBy={40} staggerDurationBy={40}>
        {ids.map(id => (
          <li key={`restaurantListItem_${id}`}>
            <ScrollElement name={`restaurantListItem_${id}`}>
              <RestaurantContainer
                id={id}
                shouldShowAddTagArea
                shouldShowDropdown
                teamSlug={teamSlug}
              />
            </ScrollElement>
          </li>
        ))}
      </FlipMove>
    );
  }
}

RestaurantList.propTypes = {
  ids: PropTypes.array.isRequired,
  restaurantListReady: PropTypes.bool.isRequired,
  teamSlug: PropTypes.string.isRequired
};

export default withStyles(s)(RestaurantList);
