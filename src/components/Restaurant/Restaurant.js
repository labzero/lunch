import React, { PropTypes } from 'react';
import RestaurantDeleteButtonContainer from '../../containers/RestaurantDeleteButtonContainer';
import RestaurantVoteCountContainer from '../../containers/RestaurantVoteCountContainer';
import RestaurantVoteButtonContainer from '../../containers/RestaurantVoteButtonContainer';
import RestaurantAddTagFormContainer from '../../containers/RestaurantAddTagFormContainer';
import RestaurantTagContainer from '../../containers/RestaurantTagContainer';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './Restaurant.scss';

export const _Restaurant = ({
  id,
  name,
  address,
  votes,
  tags,
  shouldShowAddTagArea,
  user,
  listUiItem,
  showAddTagForm,
  showMapAndInfoWindow
}) => {
  const loggedIn = user.id !== undefined;

  let deleteButton = null;
  let voteButton = null;
  if (loggedIn) {
    voteButton = <RestaurantVoteButtonContainer {...{ id, votes }} />;
    deleteButton = (
      <div className={s.deleteButtonContainer}>
        <RestaurantDeleteButtonContainer {...{ id }} />
      </div>
    );
  }

  let addTagArea = null;
  if (shouldShowAddTagArea && loggedIn) {
    if (listUiItem.isAddingTags) {
      addTagArea = <RestaurantAddTagFormContainer {...{ id }} />;
    } else {
      addTagArea = <button className="btn btn-sm btn-default" onClick={showAddTagForm}>add tag</button>;
    }
  }

  return (
    <div className={s.root}>
      <div className={s.header}>
        <h2 className={s.heading} onClick={showMapAndInfoWindow}>{name}</h2>
        <div className={s.voteButtonContainer}>
          <RestaurantVoteCountContainer votes={votes} />
          &nbsp;
          {voteButton}
        </div>
      </div>
      <a className={s.addressLink} href={`https://www.google.com/maps/place/${name}, ${address}`} target="_blank">
        {address}
      </a>
      <div className={s.footer}>
        <div className={s.tagsArea}>
          <ul className={`${s.tagList} ${tags.length === 0 ? s.tagsListEmpty : ''}`}>
            {tags.map(tag => (
              <li className={s.tagItem} key={tag}>
                <RestaurantTagContainer restaurantId={id} id={tag} />
              </li>
            ))}
          </ul>
          {addTagArea}
        </div>
        {deleteButton}
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
  listUiItem: PropTypes.object.isRequired,
  showAddTagForm: PropTypes.func.isRequired,
  showMapAndInfoWindow: PropTypes.func.isRequired
};

export default withStyles(_Restaurant, s);
