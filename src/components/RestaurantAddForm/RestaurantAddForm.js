import React, { PropTypes } from 'react';

const RestaurantAddForm = ({ handleClick, refCallback }) => (
  <form>
    <input ref={refCallback} />
    <button type="button" onClick={handleClick}>Add</button>
  </form>
);

RestaurantAddForm.propTypes = {
  handleClick: PropTypes.func.isRequired,
  refCallback: PropTypes.func.isRequired,
  user: PropTypes.object.isRequired
};

export default RestaurantAddForm;
