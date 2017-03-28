import { connect } from 'react-redux';
import { getCurrentUser } from '../../../selectors/user';
import { getTeams } from '../../../selectors/teams';
import Teams from './Teams';

const mapStateToProps = (state, ownProps) => ({
  host: state.host,
  user: getCurrentUser(state),
  teams: getTeams(state),
  title: ownProps.title
});

export default connect(mapStateToProps)(Teams);
