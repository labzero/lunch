import { connect } from 'react-redux';
import HomePage from '../../components/HomePage';

function mapStateToProps(state) {
  const { user } = state;
  return { user };
}

export default connect(mapStateToProps)(HomePage);
