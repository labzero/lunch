import React, { PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import RestaurantVoteCountContainer from '../RestaurantVoteCount/RestaurantVoteCountContainer';
import RestaurantVoteButtonContainer from '../RestaurantVoteButton/RestaurantVoteButtonContainer';
import RestaurantDecisionContainer from '../RestaurantDecision/RestaurantDecisionContainer';
import RestaurantTagListContainer from '../RestaurantTagList/RestaurantTagListContainer';
import RestaurantAddTagFormContainer from '../RestaurantAddTagForm/RestaurantAddTagFormContainer';
import RestaurantNameFormContainer from '../RestaurantNameForm/RestaurantNameFormContainer';
import RestaurantDropdownContainer from '../RestaurantDropdown/RestaurantDropdownContainer';
import s from './Restaurant.scss';

const Restaurant = ({
  restaurant,
  shouldShowAddTagArea,
  shouldShowDropdown,
  loggedIn,
  listUiItem,
  showAddTagForm,
  showMapAndInfoWindow,
  teamSlug,
}) => {
  let voteButton;
  let addTagArea;
  let dropdown;
  if (loggedIn) {
    voteButton = (
      <span className={s.voteButtonContainer}>
        <RestaurantVoteButtonContainer id={restaurant.id} />
      </span>
    );
    if (shouldShowAddTagArea) {
      if (listUiItem.isAddingTags) {
        addTagArea = <RestaurantAddTagFormContainer id={restaurant.id} />;
      } else {
        addTagArea = (
          <button className="btn btn-sm btn-default" onClick={showAddTagForm}>add tag</button>
        );
      }
    }
    if (shouldShowDropdown) {
      dropdown = (
        <div className={s.dropdownContainer}>
          <RestaurantDropdownContainer id={restaurant.id} teamSlug={teamSlug} />
        </div>
      );
    }
  }

  let nameArea;
  if (listUiItem.isEditingName && shouldShowDropdown) {
    nameArea = (
      <span className={s.restaurantNameFormContainer}>
        <RestaurantNameFormContainer
          id={restaurant.id}
          name={restaurant.name}
          teamSlug={teamSlug}
        />
      </span>
    );
  } else {
    nameArea = (
      <h2 className={s.heading}>
        <button onClick={showMapAndInfoWindow} className={s.headingButton}>
          {restaurant.name}
        </button>
        <RestaurantDecisionContainer id={restaurant.id} />
      </h2>
    );
  }

  return (
    <div className={s.root}>
      <div>
        {nameArea}
        <div className={s.voteContainer}>
          <RestaurantVoteCountContainer id={restaurant.id} />
          {voteButton}
        </div>
      </div>
      <div className={s.addressContainer}>
        <a
          href={`/api/restaurants/${restaurant.id}/place_url`}
          target="_blank"
          rel="noopener noreferrer"
        >
          {restaurant.address}
        </a>
      </div>
      <div className={s.footer}>
        <div className={s.tagsArea}>
          <RestaurantTagListContainer id={restaurant.id} />
          {addTagArea}
        </div>
        {dropdown}
      </div>
    </div>
  );
};

Restaurant.propTypes = {
  restaurant: PropTypes.object.isRequired,
  loggedIn: PropTypes.bool.isRequired,
  shouldShowAddTagArea: PropTypes.bool,
  shouldShowDropdown: PropTypes.bool,
  listUiItem: PropTypes.object.isRequired,
  showAddTagForm: PropTypes.func.isRequired,
  showMapAndInfoWindow: PropTypes.func.isRequired,
  teamSlug: PropTypes.string.isRequired
};

Restaurant.defaultProps = {
  shouldShowAddTagArea: false,
  shouldShowDropdown: false
};

export const undecorated = Restaurant;
export default withStyles(s)(Restaurant);
