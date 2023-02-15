import PropTypes from 'prop-types';
import React, { Component } from 'react';
import withStyles from 'isomorphic-style-loader/withStyles';
import Button from 'react-bootstrap/Button';
import s from './RestaurantNameForm.scss';

class RestaurantNameForm extends Component {
  componentDidMount() {
    // React Bootstrap steals focus, grab it back
    const input = this.input;
    setTimeout(() => {
      input.focus();
    }, 1);
  }

  render() {
    return (
      <form onSubmit={this.props.changeRestaurantName}>
        <span className={s.inputContainer}>
          <input
            type="text"
            className="form-control input-sm"
            value={this.props.editNameFormValue}
            onChange={this.props.setEditNameFormValue}
            ref={(i) => {
              this.input = i;
            }}
          />
        </span>
        <Button
          type="submit"
          className={s.button}
          disabled={this.props.editNameFormValue === ''}
          size="sm"
          variant="primary"
        >
          ok
        </Button>
        <Button
          className={s.button}
          onClick={this.props.hideEditNameForm}
          size="sm"
          variant="light"
        >
          cancel
        </Button>
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
