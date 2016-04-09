import React, { Component, PropTypes } from 'react';
import { OverlayTrigger, Tooltip } from 'react-bootstrap';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import s from './RestaurantVoteCount.scss';

export class _RestaurantVoteCount extends Component {
  static propTypes = {
    id: PropTypes.number.isRequired,
    votes: PropTypes.array.isRequired,
    user: PropTypes.object.isRequired,
    users: PropTypes.array.isRequired
  };

  componentDidUpdate() {
    this._el.classList.add(s.updated);
    setTimeout(() => this._el.classList.remove(s.updated), 100);
  }

  render() {
    let voteCountContainer = null;
    if (this.props.votes.length > 0) {
      const voteCount = (
        <span>
          <strong>{this.props.votes.length}</strong>
          {this.props.votes.length === 1 ? ' vote' : ' votes'}
        </span>
      );

      let tooltip;
      if (this.props.user.id === undefined) {
        voteCountContainer = voteCount;
      } else {
        tooltip = (
          <Tooltip id={`voteCountTooltip_${this.props.id}`}>{this.props.votes.map(vote => {
            const foundUser = this.props.users.find(user => user.id === vote.user_id);
            if (foundUser !== undefined) {
              return <div key={`restaurantVote_${vote.id}`}>{foundUser.name}</div>;
            }
            return null;
          })}</Tooltip>
        );
        voteCountContainer = (
          <OverlayTrigger placement="top" overlay={tooltip}>
            {voteCount}
          </OverlayTrigger>
        );
      }
    }

    return (
      <span ref={e => { this._el = e; }} className={s.root}>
        {voteCountContainer}
      </span>
    );
  }
}

export default withStyles(_RestaurantVoteCount, s);
