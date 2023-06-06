import PropTypes from "prop-types";
import React, { Component, RefObject, createRef } from "react";
import OverlayTrigger from "react-bootstrap/OverlayTrigger";
import Tooltip from "react-bootstrap/Tooltip";
import withStyles from "isomorphic-style-loader/withStyles";
import { AppContext, User } from "../../interfaces";
import TooltipUserContainer from "../TooltipUser/TooltipUserContainer";
import s from "./RestaurantVoteCount.scss";

export interface RestaurantVoteCountProps {
  id: number;
  votes: number[];
  user: Partial<User>;
}

export class _RestaurantVoteCount extends Component<RestaurantVoteCountProps> {
  context: AppContext;

  el: RefObject<HTMLSpanElement>;

  timeout: NodeJS.Timeout;

  static contextTypes = {
    store: PropTypes.object.isRequired,
  };

  static propTypes = {
    id: PropTypes.number.isRequired,
    votes: PropTypes.array.isRequired,
    user: PropTypes.object.isRequired,
  };

  constructor(props: RestaurantVoteCountProps) {
    super(props);
    this.el = createRef();
  }

  componentDidUpdate() {
    if (this.el) {
      this.el.current?.classList.add(s.updated);
      this.timeout = setTimeout(() => {
        if (this.el) {
          this.el.current?.classList.remove(s.updated);
        }
      }, 100);
    }
  }

  componentWillUnmount() {
    clearTimeout(this.timeout);
  }

  render() {
    let voteCountContainer = null;
    if (this.props.votes.length > 0) {
      const voteCount = (
        <span>
          <strong>{this.props.votes.length}</strong>
          {this.props.votes.length === 1 ? " vote" : " votes"}
        </span>
      );

      let tooltip;
      if (this.props.user.id === undefined) {
        voteCountContainer = voteCount;
      } else {
        tooltip = (
          <Tooltip id={`voteCountTooltip_${this.props.id}`}>
            {this.props.votes.map((voteId) => (
              <TooltipUserContainer
                key={`voteCountTooltipUser_${voteId}`}
                store={this.context.store}
                voteId={voteId}
              />
            ))}
          </Tooltip>
        );
        voteCountContainer = (
          <OverlayTrigger
            placement="top"
            overlay={tooltip}
            trigger={["click", "hover"]}
          >
            {voteCount}
          </OverlayTrigger>
        );
      }
    }

    return (
      <span ref={this.el} className={s.root}>
        {voteCountContainer}
      </span>
    );
  }
}

export default withStyles(s)(_RestaurantVoteCount);
