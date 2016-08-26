import React, { Component, PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './RestaurantVoteButton.scss';

export class _RestaurantVoteButton extends Component {
  componentDidUpdate() {
    // if it's focused, page scrolls to its new location once it's sorted
    this.el.blur();
  }

  render() {
    let btnClass = 'btn-primary';
    if (this.props.userVotes.length > 0) {
      btnClass = 'btn-danger';
    }

    return (
      <button
        ref={r => { this.el = r; }}
        onClick={this.props.handleClick}
        className={`${s.root} btn btn-sm ${btnClass}`}
      >
        {this.props.userVotes.length > 0 ? '-1' : '+1'}
      </button>
    );
  }
}

_RestaurantVoteButton.propTypes = {
  handleClick: PropTypes.func.isRequired,
  userVotes: PropTypes.array.isRequired
};

export default withStyles(s)(_RestaurantVoteButton);
