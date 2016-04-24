import { connect } from 'react-redux';
import { getWhitelistEmailById } from '../selectors/whitelistEmails';
import { removeWhitelistEmail } from '../actions/whitelistEmails';
import EmailWhitelistItem from '../components/EmailWhitelistItem';

const mapStateToProps = (state, ownProps) => ({
  whitelistEmail: getWhitelistEmailById(state, ownProps.id)
});

const mapDispatchToProps = (dispatch, ownProps) => ({
  handleDeleteClicked() {
    dispatch(removeWhitelistEmail(ownProps.id));
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(EmailWhitelistItem);
