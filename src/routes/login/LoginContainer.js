import { connect } from 'react-redux';
import Login from './Login';

const mapStateToProps = (state, ownProps) => ({
  host: state.host,
  teamSlug: ownProps.teamSlug
});

export default connect(mapStateToProps)(Login);
