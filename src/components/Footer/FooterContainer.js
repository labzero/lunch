import { connect } from 'react-redux';
import Footer from './Footer';

const mapStateToProps = state => ({ user: state.user });

export default connect(
  mapStateToProps
)(Footer);
