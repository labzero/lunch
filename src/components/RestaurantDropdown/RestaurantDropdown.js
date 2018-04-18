import PropTypes from 'prop-types';
import React from 'react';
import Dropdown from 'react-bootstrap/lib/Dropdown';
import Glyphicon from 'react-bootstrap/lib/Glyphicon';
import MenuItem from 'react-bootstrap/lib/MenuItem';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './RestaurantDropdown.scss';

const RestaurantDropdown = ({
  restaurant,
  sortDuration,
  listUiItem,
  decision,
  showMapAndInfoWindow,
  showEditNameForm,
  deleteRestaurant,
  removeDecision,
  showPastDecisionsModal,
}) => {
  let editButton;
  if (!listUiItem.isEditingName) {
    editButton = (
      <MenuItem onSelect={showEditNameForm} key={`restaurantDropdown_${restaurant.id}_editName`}>
        Edit name
      </MenuItem>
    );
  }

  let decideButton;
  if (decision !== undefined && decision.restaurant_id === restaurant.id) {
    decideButton = (
      <MenuItem
        onSelect={removeDecision}
        key={`restaurantDropdown_${restaurant.id}_removeDecision`}
      >
        Remove decision
      </MenuItem>
    );
  } else {
    decideButton = (
      <MenuItem onSelect={showPastDecisionsModal} key={`restaurantDropdown_${restaurant.id}_showPastDecisionsModal`}>
        We ate here...
      </MenuItem>
    );
  }

  const menuItems = [
    <MenuItem onSelect={showMapAndInfoWindow} key={`restaurantDropdown_${restaurant.id}_showMap`}>
      Reveal on map
    </MenuItem>,
    editButton,
    decideButton,
    <MenuItem
      onSelect={deleteRestaurant}
      key={`restaurantDropdown_${restaurant.id}_delete`}
    >
      Delete
    </MenuItem>
  ];

  const DropdownToggle = Dropdown.Toggle;
  const DropdownMenu = Dropdown.Menu;

  return (
    <Dropdown
      id={`restaurantDropdown_${restaurant.id}`}
      title=""
      bsRole="toggle"
      pullRight
      className={s.root}
    >
      <DropdownToggle bsRole="toggle" noCaret className={s.toggle}>
        <Glyphicon glyph="option-horizontal" />
      </DropdownToggle>
      <DropdownMenu bsRole="menu" className={s.menu}>
        {menuItems}
        <MenuItem divider />
        <MenuItem header>Last {sortDuration} day{sortDuration === 1 ? '' : 's'}:</MenuItem>
        <li className={s.stat}>
          {restaurant.all_vote_count} vote{parseInt(restaurant.all_vote_count, 10) === 1 ? '' : 's'}
        </li>
        <li className={s.stat}>
          {`${restaurant.all_decision_count} \
decision${parseInt(restaurant.all_decision_count, 10) === 1 ? '' : 's'}`}
        </li>
      </DropdownMenu>
    </Dropdown>
  );
};

RestaurantDropdown.propTypes = {
  restaurant: PropTypes.object.isRequired,
  sortDuration: PropTypes.number.isRequired,
  listUiItem: PropTypes.object.isRequired,
  decision: PropTypes.object,
  showMapAndInfoWindow: PropTypes.func.isRequired,
  showEditNameForm: PropTypes.func.isRequired,
  deleteRestaurant: PropTypes.func.isRequired,
  removeDecision: PropTypes.func,
  showPastDecisionsModal: PropTypes.func.isRequired
};

RestaurantDropdown.defaultProps = {
  decision: {},
  removeDecision: () => {}
};

export default withStyles(s)(RestaurantDropdown);
