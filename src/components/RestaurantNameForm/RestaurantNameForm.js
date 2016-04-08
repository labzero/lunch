import React, { PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './RestaurantNameForm.scss';

const RestaurantNameForm = ({
  editNameFormValue,
  setEditNameFormValue,
  changeRestaurantName,
  hideEditNameForm
}) => (
  <form className={s.root}>
    <span className={s.inputContainer}>
      <input className="form-control input-sm" value={editNameFormValue} onChange={setEditNameFormValue} />
    </span>
    <button
      type="submit"
      className={`btn btn-primary btn-sm ${s.button}`}
      onClick={changeRestaurantName}
      disabled={editNameFormValue === ''}
    >
      ok
    </button>
    <button
      type="button"
      className={`btn btn-default btn-sm ${s.button}`}
      onClick={hideEditNameForm}
    >
      cancel
    </button>
  </form>
);

RestaurantNameForm.propTypes = {
  editNameFormValue: PropTypes.string.isRequired,
  setEditNameFormValue: PropTypes.func.isRequired,
  changeRestaurantName: PropTypes.func.isRequired,
  hideEditNameForm: PropTypes.func.isRequired,
};

export default withStyles(RestaurantNameForm, s);
