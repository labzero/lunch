import React, { PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './RestaurantNameForm.scss';

const RestaurantNameForm = ({
  editNameFormValue,
  setEditNameFormValue
}) => (
  <form>
    <input className="form-control" value={editNameFormValue} onChange={setEditNameFormValue} />
  </form>
);

RestaurantNameForm.propTypes = {
  editNameFormValue: PropTypes.string.isRequired,
  setEditNameFormValue: PropTypes.func.isRequired
};

export default withStyles(RestaurantNameForm, s);
