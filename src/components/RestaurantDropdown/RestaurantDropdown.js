import PropTypes from 'prop-types';
import React from 'react';
import Dropdown from 'react-bootstrap/Dropdown';
import { FaEllipsisH } from 'react-icons/fa';
import withStyles from 'isomorphic-style-loader/withStyles';
import s from './RestaurantDropdown.scss';

const DropdownToggle = Dropdown.Toggle;
const DropdownMenu = Dropdown.Menu;
const MenuItem = Dropdown.Item;

const RestaurantDropdown = ({
  restaurant,
  sortDuration,
  listUiItem,
  decision,
  pastDecisions,
  showMapAndInfoWindow,
  showEditNameForm,
  deleteRestaurant,
  removeDecision,
  showPastDecisionsModal,
}) => {
  let editButton;
  if (!listUiItem.isEditingName) {
    editButton = (
      <MenuItem
        onClick={showEditNameForm}
        key={`restaurantDropdown_${restaurant.id}_editName`}
      >
        Edit name
      </MenuItem>
    );
  }

  let decideButton;
  if (decision !== undefined && decision.restaurantId === restaurant.id) {
    decideButton = (
      <MenuItem
        onClick={removeDecision}
        key={`restaurantDropdown_${restaurant.id}_removeDecision`}
      >
        Remove decision
      </MenuItem>
    );
  } else {
    decideButton = (
      <MenuItem
        onClick={showPastDecisionsModal}
        key={`restaurantDropdown_${restaurant.id}_showPastDecisionsModal`}
      >
        We ate here...
      </MenuItem>
    );
  }

  const menuItems = [
    <MenuItem
      onClick={showMapAndInfoWindow}
      key={`restaurantDropdown_${restaurant.id}_showMap`}
    >
      Reveal on map
    </MenuItem>,
    editButton,
    decideButton,
    <MenuItem
      onClick={deleteRestaurant}
      key={`restaurantDropdown_${restaurant.id}_delete`}
    >
      Delete
    </MenuItem>,
  ];

  let lastVisited;
  if (pastDecisions && pastDecisions[restaurant.id]) {
    lastVisited = (
      <>
        <Dropdown.Divider />
        <Dropdown.Header>Last visited:</Dropdown.Header>
        <li className={s.stat}>{pastDecisions[restaurant.id]}</li>
      </>
    );
  }

  return (
    <Dropdown
      id={`restaurantDropdown_${restaurant.id}`}
      title=""
      className={s.root}
    >
      <DropdownToggle className={s.toggle} variant="light">
        <FaEllipsisH />
      </DropdownToggle>
      <DropdownMenu className={s.menu}>
        {menuItems}
        {lastVisited}
        <Dropdown.Divider />
        <Dropdown.Header>
          Last
          {' '}
          {sortDuration}
          {' '}
          day
          {sortDuration === 1 ? '' : 's'}
          :
        </Dropdown.Header>
        <Dropdown.ItemText className={s.stat}>
          {restaurant.all_vote_count}
          {' '}
          vote
          {parseInt(restaurant.all_vote_count, 10) === 1 ? '' : 's'}
        </Dropdown.ItemText>
        <Dropdown.ItemText className={s.stat}>
          {`${restaurant.all_decision_count} \
decision${parseInt(restaurant.all_decision_count, 10) === 1 ? '' : 's'}`}
        </Dropdown.ItemText>
      </DropdownMenu>
    </Dropdown>
  );
};

RestaurantDropdown.propTypes = {
  restaurant: PropTypes.object.isRequired,
  sortDuration: PropTypes.number.isRequired,
  listUiItem: PropTypes.object.isRequired,
  decision: PropTypes.object,
  pastDecisions: PropTypes.object,
  showMapAndInfoWindow: PropTypes.func.isRequired,
  showEditNameForm: PropTypes.func.isRequired,
  deleteRestaurant: PropTypes.func.isRequired,
  removeDecision: PropTypes.func,
  showPastDecisionsModal: PropTypes.func.isRequired,
};

RestaurantDropdown.defaultProps = {
  decision: {},
  pastDecisions: {},
  removeDecision: () => {},
};

export default withStyles(s)(RestaurantDropdown);
