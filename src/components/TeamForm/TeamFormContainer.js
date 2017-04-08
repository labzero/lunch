import { connect } from 'react-redux';
import { injectIntl } from 'react-intl';
import { flashSuccess } from '../../actions/flash';
import { updateTeam } from '../../actions/team';
import { getCenter } from '../../selectors/mapUi';
import { getTeam } from '../../selectors/team';
import TeamForm from './TeamForm';

const mapStateToProps = state => ({
  center: getCenter(state),
  team: getTeam(state)
});

const mapDispatchToProps = dispatch => ({
  updateTeam: payload => dispatch(updateTeam(payload))
    .then(() => dispatch(flashSuccess('Team info updated.')))
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(
  injectIntl(TeamForm)
);
