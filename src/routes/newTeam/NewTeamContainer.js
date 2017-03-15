import { connect } from 'react-redux';
import NewTeam from './NewTeam';

const mapDispatchToProps = () => ({
  // createNewTeam: name => dispatch(createNewTeam(name))
});

export default connect(null, mapDispatchToProps)(NewTeam);
