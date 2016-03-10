import React, { PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './RestaurantAddTagForm.scss';

const RestaurantAddTagForm = ({ hideAddTagForm }) => (
  <form>
    <input />
    <button>add</button>
    <button type="button" onClick={hideAddTagForm}>cancel</button>
  </form>
);

RestaurantAddTagForm.propTypes = {
  hideAddTagForm: PropTypes.func.isRequired
};

export default withStyles(RestaurantAddTagForm, s);
