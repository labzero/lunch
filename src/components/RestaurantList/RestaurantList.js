import PropTypes from 'prop-types';
import React, { useCallback } from 'react';
import { Flipper, Flipped } from 'react-flip-toolkit';
import { Element as ScrollElement } from 'react-scroll';
import withStyles from 'isomorphic-style-loader/withStyles';
import Grid from 'react-bootstrap/lib/Grid';
import RestaurantContainer from '../Restaurant/RestaurantContainer';
import Loading from '../Loading';
import s from './RestaurantList.scss';

const RestaurantList = ({
  allRestaurantIds,
  flipMove,
  ids,
  restaurantListReady,
}) => {
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
          <p>Nothing to see here!</p>
        </Grid>
      </div>
    );
  }

  const shouldFlip = useCallback(() => flipMove, []);

  const onAppear = useCallback((el, i) => {
    setTimeout(() => {
      el.classList.add(s.fadeIn);
      setTimeout(() => {
        // eslint-disable-next-line no-param-reassign
        el.style.opacity = 1;
        el.classList.remove(s.fadeIn);
      }, 500);
    }, i * 50);
  }, []);

  const onExit = useCallback((el, i, removeElement) => {
    setTimeout(() => {
      el.classList.add(s.fadeOut);
      setTimeout(removeElement, 500);
    }, i * 50);
  }, []);

  const handleEnterUpdateDelete = useCallback(({
    hideEnteringElements,
    animateEnteringElements,
    animateExitingElements,
    animateFlippedElements
  }) => {
    hideEnteringElements();
    animateEnteringElements();
    animateExitingElements()
      .then(animateFlippedElements);
  }, []);

  return (
    <Flipper
      element="ul"
      className={s.root}
      flipKey={ids}
      handleEnterUpdateDelete={handleEnterUpdateDelete}
      staggerConfig={{
        default: {
          reverse: true,
          speed: 0.75,
        }
      }}
    >
      {ids.map((id) => (
        <Flipped key={id} flipId={id} onAppear={onAppear} onExit={onExit} shouldFlip={shouldFlip} stagger>
          <li key={`restaurantListItem_${id}`}>
            <ScrollElement name={`restaurantListItem_${id}`}>
              <RestaurantContainer
                id={id}
                shouldShowAddTagArea
                shouldShowDropdown
              />
            </ScrollElement>
          </li>
        </Flipped>
      ))}
    </Flipper>
  );
};

RestaurantList.propTypes = {
  allRestaurantIds: PropTypes.array.isRequired,
  flipMove: PropTypes.bool.isRequired,
  ids: PropTypes.array.isRequired,
  restaurantListReady: PropTypes.bool.isRequired,
};

export default withStyles(s)(RestaurantList);
