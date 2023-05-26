import React, { Component, RefObject } from "react";
import withStyles from "isomorphic-style-loader/withStyles";
import { Vote } from "../../interfaces";
import s from "./RestaurantVoteButton.scss";

export interface RestaurantVoteButtonProps {
  handleClick: () => void;
  userVotes: Partial<Vote>[];
}

export class _RestaurantVoteButton extends Component<RestaurantVoteButtonProps> {
  el: RefObject<HTMLButtonElement>;

  componentDidUpdate() {
    // if it's focused, page scrolls to its new location once it's sorted
    this.el.current?.blur();
  }

  render() {
    let btnClass = "btn-primary";
    if (this.props.userVotes.length > 0) {
      btnClass = "btn-danger";
    }

    return (
      <button
        ref={this.el}
        onClick={this.props.handleClick}
        className={`${s.root} btn btn-sm ${btnClass}`}
        type="button"
      >
        {this.props.userVotes.length > 0 ? "-1" : "+1"}
      </button>
    );
  }
}

export default withStyles(s)(_RestaurantVoteButton);
