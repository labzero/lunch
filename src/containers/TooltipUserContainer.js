import { connect } from 'react-redux';
import { getVoteById } from '../selectors/votes';
import { getUserByVoteId } from '../selectors';
import TooltipUser from '../components/TooltipUser';

const mapStateToProps = (state, ownProps) => ({
  vote: getVoteById(state, ownProps.voteId),
  user: getUserByVoteId(state, ownProps.voteId)
});

export default connect(
  mapStateToProps
)(TooltipUser);
