import { connect } from 'react-redux';
import Header from '../components/Header';

const mapStateToProps = state => ({ flashes: state.flashes });

export default connect(mapStateToProps)(Header);
