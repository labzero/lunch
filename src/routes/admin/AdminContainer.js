import { connect } from 'react-redux';
import { getUsers } from '../../selectors/users';
import { getTeam } from '../../selectors/team';
import Admin from './Admin';

const mapStateToProps = (state, ownProps) => ({
  users: getUsers(state),
  team: getTeam(state),
  title: ownProps.title
});

export default connect(mapStateToProps)(Admin);
