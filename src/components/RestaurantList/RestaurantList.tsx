import React, { useCallback } from "react";
import { Flipper, Flipped } from "react-flip-toolkit";
import {
  CallbackFlippedProps,
  HandleEnterUpdateDelete,
  // eslint-disable-next-line import/no-unresolved
} from "flip-toolkit/lib/types";
import { Element as ScrollElement } from "react-scroll";
import withStyles from "isomorphic-style-loader/withStyles";
import Container from "react-bootstrap/Container";
import Loading from "../Loading/Loading";
import RestaurantContainer from "../Restaurant/RestaurantContainer";
import s from "./RestaurantList.scss";

interface RestaurantListProps {
  allRestaurantIds: number[];
  flipMove: boolean;
  ids: number[];
  restaurantListReady: boolean;
}

const RestaurantList = ({
  allRestaurantIds,
  flipMove,
  ids,
  restaurantListReady,
}: RestaurantListProps) => {
  if (!restaurantListReady) {
    return <Loading />;
  }

  if (!allRestaurantIds.length) {
    return (
      <div className={s.root}>
        <Container className={s.welcome}>
          <h2>Welcome to Lunch!</h2>
          <p>
            Get started by adding restaurants! Use the above map or search box
            and add as many restaurants as you like. Then you and your team can
            start voting!
          </p>
        </Container>
      </div>
    );
  }

  if (!ids.length) {
    return (
      <div className={s.root}>
        <Container className={s.nothing}>
          <p>Nothing to see here!</p>
        </Container>
      </div>
    );
  }

  const shouldFlip = useCallback(() => flipMove, []);

  const onAppear = useCallback<NonNullable<CallbackFlippedProps["onAppear"]>>(
    (el, i) => {
      setTimeout(() => {
        el.classList.add(s.fadeIn);
        setTimeout(() => {
          // eslint-disable-next-line no-param-reassign
          el.style.opacity = "1";
          el.classList.remove(s.fadeIn);
        }, 500);
      }, i * 50);
    },
    []
  );

  const onExit = useCallback<NonNullable<CallbackFlippedProps["onExit"]>>(
    (el, i, removeElement) => {
      setTimeout(() => {
        el.classList.add(s.fadeOut);
        setTimeout(removeElement, 500);
      }, i * 50);
    },
    []
  );

  const handleEnterUpdateDelete: HandleEnterUpdateDelete = useCallback(
    ({
      hideEnteringElements,
      animateEnteringElements,
      animateExitingElements,
      animateFlippedElements,
    }) => {
      hideEnteringElements();
      animateEnteringElements();
      animateExitingElements().then(animateFlippedElements);
    },
    []
  );

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
        },
      }}
    >
      {ids.map((id) => (
        <Flipped
          key={id}
          flipId={id}
          onAppear={onAppear}
          onExit={onExit}
          shouldFlip={shouldFlip}
          stagger
        >
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

export default withStyles(s)(RestaurantList);
