import { connect } from 'react-redux';
import Header from './Header';

const mapStateToProps = state => ({ flashes: state.flashes });

export default connect(mapStateToProps)(Header);
