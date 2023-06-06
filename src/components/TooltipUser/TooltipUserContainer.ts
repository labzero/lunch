import { connect } from "react-redux";
import { State } from "../../interfaces";
import { getVoteById } from "../../selectors/votes";
import { getUserByVoteId } from "../../selectors";
import TooltipUser from "./TooltipUser";

const mapStateToProps = (state: State, ownProps: { voteId: number }) => ({
  vote: getVoteById(state, ownProps.voteId),
  user: getUserByVoteId(state, ownProps.voteId),
});

export default connect(mapStateToProps)(TooltipUser);
