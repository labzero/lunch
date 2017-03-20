import { connect } from 'react-redux';
import { getUsersWithTeamRole } from '../../../../selectors';
import Admin from './Admin';

const mapStateToProps = (state, ownProps) => ({
  users: getUsersWithTeamRole(state, ownProps.teamSlug),
  title: ownProps.title
});

export default connect(mapStateToProps)(Admin);
