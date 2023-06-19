import { Reducer } from "../interfaces";

const team: Reducer<"team"> = (state, action) => {
  switch (action.type) {
    case "TEAM_PATCHED": {
      return action.team;
    }
    default:
      break;
  }
  return state;
};

export default team;
