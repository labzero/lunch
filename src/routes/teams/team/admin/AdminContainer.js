import { connect } from 'react-redux';
import { getUsers } from '../../../../selectors/users';
import Admin from './Admin';

const mapStateToProps = (state, ownProps) => ({
  users: getUsers(state),
  title: ownProps.title
});

export default connect(mapStateToProps)(Admin);
