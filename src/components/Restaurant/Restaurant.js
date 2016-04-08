import React, { PropTypes } from 'react';
import RestaurantVoteCountContainer from '../../containers/RestaurantVoteCountContainer';
import RestaurantVoteButtonContainer from '../../containers/RestaurantVoteButtonContainer';
import RestaurantAddTagFormContainer from '../../containers/RestaurantAddTagFormContainer';
import RestaurantNameFormContainer from '../../containers/RestaurantNameFormContainer';
import RestaurantDropdownContainer from '../../containers/RestaurantDropdownContainer';
import TagContainer from '../../containers/TagContainer';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './Restaurant.scss';

export const _Restaurant = ({
  id,
  name,
  address,
  votes,
  tags,
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
        <RestaurantVoteButtonContainer {...{ id, votes }} />
      </span>
    );
    if (shouldShowAddTagArea) {
      if (listUiItem.isAddingTags) {
        addTagArea = <RestaurantAddTagFormContainer {...{ id }} />;
      } else {
        addTagArea = <button className="btn btn-sm btn-default" onClick={showAddTagForm}>add tag</button>;
      }
    }
    if (shouldShowDropdown) {
      dropdown = (
        <div className={s.dropdownContainer}>
          <RestaurantDropdownContainer id={id} />
        </div>
      );
    }
  }

  let nameArea;
  if (listUiItem.isEditingName && shouldShowDropdown) {
    nameArea = (
      <span className={s.restaurantNameFormContainer}>
        <RestaurantNameFormContainer id={id} name={name} />
      </span>
    );
  } else {
    nameArea = (
      <h2 className={s.heading} onClick={showMapAndInfoWindow}>
        <span>{name}</span>
      </h2>
    );
  }

  return (
    <div className={s.root}>
      <div className={s.header}>
        {nameArea}
        <div className={s.voteContainer}>
          <RestaurantVoteCountContainer {...{ votes }} />
          {voteButton}
        </div>
      </div>
      <div className={s.addressContainer}>
        <a className={s.addressLink} href={`https://www.google.com/maps/place/${name}, ${address}`} target="_blank">
          {address}
        </a>
      </div>
      <div className={s.footer}>
        <div className={s.tagsArea}>
          <ul className={`${s.tagList} ${tags.length === 0 ? s.tagsListEmpty : ''}`}>
            {tags.map(tag => {
              const boundRemoveTag = removeTag.bind(undefined, tag);
              return (
                <li className={s.tagItem} key={`restaurantTag_${tag}`}>
                  <TagContainer id={tag} showDelete={loggedIn} onDeleteClicked={boundRemoveTag} />
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
  id: PropTypes.number.isRequired,
  name: PropTypes.string.isRequired,
  address: PropTypes.string.isRequired,
  user: PropTypes.object.isRequired,
  votes: PropTypes.array.isRequired,
  tags: PropTypes.array.isRequired,
  shouldShowAddTagArea: PropTypes.bool,
  shouldShowDropdown: PropTypes.bool,
  listUiItem: PropTypes.object.isRequired,
  showAddTagForm: PropTypes.func.isRequired,
  showMapAndInfoWindow: PropTypes.func.isRequired,
  removeTag: PropTypes.func.isRequired,
};

export default withStyles(_Restaurant, s);
