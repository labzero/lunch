import PropTypes from 'prop-types';
import React, { Component } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './NameFilterForm.scss';

class NameFilterForm extends Component {
  static propTypes = {
    nameFilter: PropTypes.string.isRequired,
    restaurantIds: PropTypes.array.isRequired,
    setFlipMove: PropTypes.func.isRequired,
    setNameFilter: PropTypes.func.isRequired,
  };

  constructor(props) {
    super(props);

    if (props.nameFilter.length) {
      this.state = {
        shown: true,
      };
    } else {
      this.state = {
        shown: false,
      };
    }
  }

  componentDidUpdate(prevProps, prevState) {
    if (this.state.shown !== prevState.shown) {
      if (this.state.shown) {
        this.input.focus();
      } else {
        this.setFlipMoveTrue();
      }
    }
  }

  setFlipMoveFalse = () => {
    this.props.setFlipMove(false);
  }

  setFlipMoveTrue = () => {
    this.props.setFlipMove(true);
  }

  setNameFilterValue = (event) => {
    this.props.setNameFilter(event.target.value);
  }

  hideForm = () => {
    this.props.setFlipMove(false);
    this.props.setNameFilter('');
    this.setState(() => ({
      shown: false,
    }));
  }

  showForm = () => {
    this.setState(() => ({
      shown: true,
    }));
  }

  render() {
    const {
      nameFilter,
      restaurantIds,
    } = this.props;

    const { shown } = this.state;

    let child;

    if (!restaurantIds.length) {
      return null;
    }

    if (shown) {
      child = (
        <form className={s.form}>
          <div className={s.container}>
            <input
              className={`${s.input} form-control`}
              placeholder="filter"
              value={nameFilter}
              onChange={this.setNameFilterValue}
              onFocus={this.setFlipMoveFalse}
              onBlur={this.setFlipMoveTrue}
              ref={i => { this.input = i; }}
            />
          </div>
          <button
            className="btn btn-default"
            type="button"
            onClick={this.hideForm}
          >
            cancel
          </button>
        </form>
      );
    } else {
      child = (
        <button className="btn btn-default" onClick={this.showForm}>
          filter by name
        </button>
      );
    }
    return (
      <div className={s.root}>{child}</div>
    );
  }
}

export const undecorated = NameFilterForm;
export default withStyles(s)(NameFilterForm);
