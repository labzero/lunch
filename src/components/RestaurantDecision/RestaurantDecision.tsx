import React from "react";
import OverlayTrigger from "react-bootstrap/OverlayTrigger";
import Tooltip from "react-bootstrap/Tooltip";
import withStyles from "isomorphic-style-loader/withStyles";
import { Vote } from "../../interfaces";
import s from "./RestaurantDecision.scss";

interface RestaurantDecisionProps {
  id: number;
  votes: Vote[];
  decided: boolean;
  loggedIn: boolean;
  handleClick: () => void;
}

const RestaurantDecision = ({
  id,
  votes,
  decided,
  loggedIn,
  handleClick,
}: RestaurantDecisionProps) => {
  const tooltip = (
    <Tooltip id={`restaurantDecisionTooltip_${id}`}>
      We ate here
      {decided ? "!" : "?"}
    </Tooltip>
  );

  return (
    ((loggedIn && votes.length > 0) || decided) && (
      <OverlayTrigger placement="top" overlay={tooltip}>
        <span
          className={`${s.root} ${loggedIn ? "" : s.loggedOut} ${
            decided ? s.decided : ""
          }`}
          onClick={handleClick}
          onKeyUp={handleClick}
          role="button"
          tabIndex={0}
        >
          ✔
        </span>
      </OverlayTrigger>
    )
  );
};

export default withStyles(s)(RestaurantDecision);
