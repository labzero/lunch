import { connect } from 'react-redux';
import { getTeam } from '../../selectors/team';
import { removeTeam } from '../../actions/team';
import { hideModal } from '../../actions/modals';
import DeleteTeamModal from './DeleteTeamModal';

const modalName = 'deleteTeam';

const mapStateToProps = state => ({
  host: state.host,
  team: getTeam(state),
  shown: !!state.modals[modalName].shown
});

const mapDispatchToProps = dispatch => ({
  hideModal: () => {
    dispatch(hideModal(modalName));
  },
  dispatch
});

const mergeProps = (stateProps, dispatchProps) => ({ ...stateProps, ...dispatchProps, deleteTeam: () => dispatchProps.dispatch(removeTeam()) });

export default connect(
  mapStateToProps,
  mapDispatchToProps,
  mergeProps
)(DeleteTeamModal);
