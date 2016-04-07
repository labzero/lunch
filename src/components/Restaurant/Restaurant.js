import React, { PropTypes } from 'react';
import RestaurantDeleteButtonContainer from '../../containers/RestaurantDeleteButtonContainer';
import RestaurantVoteCountContainer from '../../containers/RestaurantVoteCountContainer';
import RestaurantVoteButtonContainer from '../../containers/RestaurantVoteButtonContainer';
import RestaurantAddTagFormContainer from '../../containers/RestaurantAddTagFormContainer';
import RestaurantNameFormContainer from '../../containers/RestaurantNameFormContainer';
import { DropdownButton, MenuItem } from 'react-bootstrap';
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
  shouldShowCrosshairs,
  shouldShowTagDelete,
  user,
  listUiItem,
  showAddTagForm,
  showEditNameForm,
  showMapAndInfoWindow,
  removeTag
}) => {
  const loggedIn = user.id !== undefined;

  let deleteButton;
  let voteButton;
  if (loggedIn) {
    voteButton = (
      <span className={s.voteButtonContainer}>
        <RestaurantVoteButtonContainer {...{ id, votes }} />
      </span>
    );
    deleteButton = (
      <div className={s.deleteButtonContainer}>
        <RestaurantDeleteButtonContainer {...{ id }} />
      </div>
    );
  }

  let addTagArea;
  if (shouldShowAddTagArea && loggedIn) {
    if (listUiItem.isAddingTags) {
      addTagArea = <RestaurantAddTagFormContainer {...{ id }} />;
    } else {
      addTagArea = <button className="btn btn-sm btn-default" onClick={showAddTagForm}>add tag</button>;
    }
  }

  let nameArea;
  if (listUiItem.isEditingName) {
    nameArea = <RestaurantNameFormContainer id={id} name={name} shouldShowCrosshairs={shouldShowCrosshairs} />;
  } else {
    let crosshairs;
    if (shouldShowCrosshairs) {
      crosshairs = (
        <button onClick={showMapAndInfoWindow} className={`glyphicon glyphicon-screenshot ${s.tool}`}>
        </button>
      );
    }

    let editButton;
    if (user.id !== undefined) {
      editButton = (
        <button onClick={showEditNameForm} className={`glyphicon glyphicon-pencil ${s.tool}`}>
        </button>
      );
    }

    nameArea = (
      <h2 className={s.heading}>
        <span onClick={showMapAndInfoWindow}>
          {name}
        </span>
        <span className={s.tools}>
          {crosshairs}
          {editButton}
        </span>
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
                  <TagContainer id={tag} showDelete={shouldShowTagDelete} onDeleteClicked={boundRemoveTag} />
                </li>
              );
            })}
          </ul>
          {addTagArea}
        </div>
        <DropdownButton
          id={`restaurantDropdown_${id}`}
          title=""
          bsRole="toggle"
          noCaret
          className="glyphicon glyphicon-option-horizontal"
        >
          <MenuItem>
            { /* deleteButton */ }
            Hello.
          </MenuItem>
        </DropdownButton>
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
  shouldShowCrosshairs: PropTypes.bool,
  listUiItem: PropTypes.object.isRequired,
  showAddTagForm: PropTypes.func.isRequired,
  showEditNameForm: PropTypes.func.isRequired,
  showMapAndInfoWindow: PropTypes.func.isRequired,
  removeTag: PropTypes.func.isRequired,
  shouldShowTagDelete: PropTypes.bool.isRequired
};

export default withStyles(_Restaurant, s);
