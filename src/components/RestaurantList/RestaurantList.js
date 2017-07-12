import PropTypes from 'prop-types';
import React from 'react';
import FlipMove from 'react-flip-move';
import { Element as ScrollElement } from 'react-scroll';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import Grid from 'react-bootstrap/lib/Grid';
import RestaurantContainer from '../Restaurant/RestaurantContainer';
import Loading from '../Loading';
import s from './RestaurantList.scss';

const RestaurantList = ({ allRestaurantIds, flipMove, ids, restaurantListReady }) => {
  if (!restaurantListReady) {
    return <Loading />;
  }

  if (!allRestaurantIds.length) {
    return (
      <div className={s.root}>
        <Grid className={s.welcome}>
          <h2>Welcome to Lunch!</h2>
          <p>
            Get started by adding restaurants! Use the above map or search box
            and add as many restaurants as you like. Then you and your team can
            start voting!
          </p>
        </Grid>
      </div>
    );
  }

  if (!ids.length) {
    return (
      <div className={s.root}>
        <Grid className={s.nothing}>
          <p>
            Nothing to see here!
          </p>
        </Grid>
      </div>
    );
  }

  return (
    <FlipMove
      typeName="ul"
      className={s.root}
      disableAllAnimations={!flipMove}
      enterAnimation="fade"
      leaveAnimation="fade"
      staggerDelayBy={40}
      staggerDurationBy={40}
    >
      {ids.map(id => (
        <li key={`restaurantListItem_${id}`}>
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
  );
};

RestaurantList.propTypes = {
  allRestaurantIds: PropTypes.array.isRequired,
  flipMove: PropTypes.bool.isRequired,
  ids: PropTypes.array.isRequired,
  restaurantListReady: PropTypes.bool.isRequired
};

export default withStyles(s)(RestaurantList);
