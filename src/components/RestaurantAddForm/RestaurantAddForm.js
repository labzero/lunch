import React, { PropTypes } from 'react';
import { connect } from 'react-redux';
import { addRestaurant } from '../actions/restaurants';

const RestaurantAddForm = ({ dispatch }) => {
  let input;
  render(
    <form>
      <input ref={node => {input = node}} />
      <button onClick={() => {
        dispatch(addRestaurant(input.value));
        input.value = '';
      }} />
    </form>
  );
}

export default connect(mapStateToProps)(RestaurantAddForm)