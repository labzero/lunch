import React, { PropTypes } from 'react';
import { Dropdown, Glyphicon, MenuItem } from 'react-bootstrap';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './RestaurantDropdown.scss';

const RestaurantDropdown = ({ id, listUiItem, showMapAndInfoWindow, showEditNameForm, deleteRestaurant }) => {
  let editButton;
  if (!listUiItem.isEditingName) {
    editButton = <MenuItem onSelect={showEditNameForm} key={`restaurantDropdown_${id}_editName`}>Edit name</MenuItem>;
  }

  const menuItems = [
    <MenuItem onSelect={showMapAndInfoWindow} key={`restaurantDropdown_${id}_showMap`}>Reveal on map</MenuItem>,
    editButton,
    <MenuItem onSelect={deleteRestaurant} key={`restaurantDropdown_${id}_delete`}>Delete</MenuItem>
  ];

  const DropdownToggle = Dropdown.Toggle;
  const DropdownMenu = Dropdown.Menu;

  return (
    <Dropdown
      id={`restaurantDropdown_${id}`}
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
      </DropdownMenu>
    </Dropdown>
  );
};

RestaurantDropdown.propTypes = {
  id: PropTypes.number.isRequired,
  listUiItem: PropTypes.object.isRequired,
  showMapAndInfoWindow: PropTypes.func.isRequired,
  showEditNameForm: PropTypes.func.isRequired,
  deleteRestaurant: PropTypes.func.isRequired
};

export default withStyles(RestaurantDropdown, s);
