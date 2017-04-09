import { connect } from 'react-redux';
import { showModal } from '../../../actions/modals';
import { removeUser } from '../../../actions/users';
import { getCurrentUser } from '../../../selectors/user';
import { getTeams } from '../../../selectors/teams';
import Teams from './Teams';

const mapStateToProps = (state, ownProps) => ({
  host: state.host,
  user: getCurrentUser(state),
  teams: getTeams(state),
  title: ownProps.title
});

const mapDispatchToProps = dispatch => ({
  confirm: opts => dispatch(showModal('confirm', opts)),
  dispatch
});

const mergeProps = (stateProps, dispatchProps) => Object.assign({}, stateProps, dispatchProps, {
  leaveTeam: team => dispatchProps.dispatch(removeUser(stateProps.user.id, team))
});

export default connect(
  mapStateToProps,
  mapDispatchToProps,
  mergeProps
)(Teams);
