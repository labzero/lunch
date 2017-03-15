import { connect } from 'react-redux';
import NewTeam from './NewTeam';
import { createTeam } from '../../actions/teams';

const mapDispatchToProps = dispatch => ({
  createTeam: payload => dispatch(createTeam(payload))
});

export default connect(null, mapDispatchToProps)(NewTeam);
