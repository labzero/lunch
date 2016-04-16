import React, { PropTypes } from 'react';
import RestaurantVoteCountContainer from '../../containers/RestaurantVoteCountContainer';
import RestaurantVoteButtonContainer from '../../containers/RestaurantVoteButtonContainer';
import RestaurantDecisionContainer from '../../containers/RestaurantDecisionContainer';
import RestaurantAddTagFormContainer from '../../containers/RestaurantAddTagFormContainer';
import RestaurantNameFormContainer from '../../containers/RestaurantNameFormContainer';
import RestaurantDropdownContainer from '../../containers/RestaurantDropdownContainer';
import TagContainer from '../../containers/TagContainer';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './Restaurant.scss';

export const _Restaurant = ({
  restaurant,
  shouldShowAddTagArea,
  shouldShowDropdown,
  user,
  listUiItem,
  showAddTagForm,
  showMapAndInfoWindow,
  removeTag
}) => {
  const loggedIn = user.id !== undefined;

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
        addTagArea = <button className="btn btn-sm btn-default" onClick={showAddTagForm}>add tag</button>;
      }
    }
    if (shouldShowDropdown) {
      dropdown = (
        <div className={s.dropdownContainer}>
          <RestaurantDropdownContainer id={restaurant.id} />
        </div>
      );
    }
  }

  let nameArea;
  if (listUiItem.isEditingName && shouldShowDropdown) {
    nameArea = (
      <span className={s.restaurantNameFormContainer}>
        <RestaurantNameFormContainer id={restaurant.id} name={restaurant.name} />
      </span>
    );
  } else {
    nameArea = (
      <h2 className={s.heading}>
        <span onClick={showMapAndInfoWindow}>{restaurant.name}</span>
        <RestaurantDecisionContainer id={restaurant.id} />
      </h2>
    );
  }

  return (
    <div className={s.root}>
      <div className={s.header}>
        {nameArea}
        <div className={s.voteContainer}>
          <RestaurantVoteCountContainer id={restaurant.id} />
          {voteButton}
        </div>
      </div>
      <div className={s.addressContainer}>
        <a className={s.addressLink} href={`/api/restaurants/${restaurant.id}/place_url`} target="_blank">
          {restaurant.address}
        </a>
      </div>
      <div className={s.footer}>
        <div className={s.tagsArea}>
          <ul className={`${s.tagList} ${restaurant.tags.length === 0 ? s.tagsListEmpty : ''}`}>
            {restaurant.tags.map(tagId => {
              const boundRemoveTag = removeTag.bind(undefined, tagId);
              return (
                <li className={s.tagItem} key={`restaurantTag_${tagId}`}>
                  <TagContainer id={tagId} showDelete={loggedIn} onDeleteClicked={boundRemoveTag} />
                </li>
              );
            })}
          </ul>
          {addTagArea}
        </div>
        {dropdown}
      </div>
    </div>
  );
};

_Restaurant.propTypes = {
  restaurant: PropTypes.object.isRequired,
  user: PropTypes.object.isRequired,
  shouldShowAddTagArea: PropTypes.bool,
  shouldShowDropdown: PropTypes.bool,
  listUiItem: PropTypes.object.isRequired,
  showAddTagForm: PropTypes.func.isRequired,
  showMapAndInfoWindow: PropTypes.func.isRequired,
  removeTag: PropTypes.func.isRequired,
};

export default withStyles(s)(_Restaurant);
