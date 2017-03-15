import { connect } from 'react-redux';
import Home from './Home';

const mapStateToProps = state => ({
  loggedIn: state.user.id !== undefined,
});

export default connect(mapStateToProps)(Home);
