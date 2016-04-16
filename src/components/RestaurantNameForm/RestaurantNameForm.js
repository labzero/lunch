import React, { Component, PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './RestaurantNameForm.scss';

class RestaurantNameForm extends Component {
  componentDidMount() {
    // React Bootstrap steals focus, grab it back
    const input = this._input;
    setTimeout(() => {
      input.focus();
    }, 1);
  }

  render() {
    return (
      <form className={s.root} onSubmit={this.props.changeRestaurantName}>
        <span className={s.inputContainer}>
          <input
            type="text"
            className="form-control input-sm"
            value={this.props.editNameFormValue}
            onChange={this.props.setEditNameFormValue}
            ref={i => { this._input = i; }}
          />
        </span>
        <button
          type="submit"
          className={`btn btn-primary btn-sm ${s.button}`}
          disabled={this.props.editNameFormValue === ''}
        >
          ok
        </button>
        <button
          type="button"
          className={`btn btn-default btn-sm ${s.button}`}
          onClick={this.props.hideEditNameForm}
        >
          cancel
        </button>
      </form>
    );
  }
}

RestaurantNameForm.propTypes = {
  editNameFormValue: PropTypes.string.isRequired,
  setEditNameFormValue: PropTypes.func.isRequired,
  changeRestaurantName: PropTypes.func.isRequired,
  hideEditNameForm: PropTypes.func.isRequired,
};

export default withStyles(s)(RestaurantNameForm);
