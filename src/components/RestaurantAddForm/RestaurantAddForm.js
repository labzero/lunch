import React, { PropTypes } from 'react';
import Geosuggest from 'react-geosuggest';

const RestaurantAddForm = ({ handleClick, refCallback }) => (
  <form>
    <Geosuggest />
    <input ref={refCallback} />
    <button type="button" onClick={handleClick}>Add</button>
  </form>
);

RestaurantAddForm.propTypes = {
  handleClick: PropTypes.func.isRequired,
  refCallback: PropTypes.func.isRequired
};

export default RestaurantAddForm;
