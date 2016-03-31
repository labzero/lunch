import React, { Component, PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './RestaurantVoteButton.scss';

class _RestaurantVoteButton extends Component {
  componentDidUpdate() {
    this._el.blur();
  }

  render() {
    let downVote = false;
    let btnClass = 'btn-primary';
    if (this.props.votes.some(vote => vote.user_id === this.props.user.id)) {
      downVote = true;
      btnClass = 'btn-danger';
    }

    return (
      <button ref={r => { this._el = r; }} onClick={this.props.handleClick} className={`btn btn-sm ${btnClass}`}>
        {downVote ? '-1' : '+1'}
      </button>
    );
  }
}

_RestaurantVoteButton.propTypes = {
  handleClick: PropTypes.func.isRequired,
  user: PropTypes.shape({
    id: PropTypes.number.isRequired
  }).isRequired,
  votes: PropTypes.arrayOf(PropTypes.shape({
    user_id: PropTypes.number.isRequired
  })).isRequired
};

export default withStyles(_RestaurantVoteButton, s);
