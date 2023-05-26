import React from "react";
import { User, Vote } from "../../interfaces";

export interface TooltipUserProps {
  vote: Vote;
  user: User;
}

const TooltipUser = ({ vote, user }: TooltipUserProps) => {
  if (user !== undefined) {
    return <div key={`restaurantVote_${vote.id}`}>{user.name}</div>;
  }
  return null;
};

export default TooltipUser;
