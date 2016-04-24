import { connect } from 'react-redux';
import { getWhitelistEmailIds } from '../selectors/whitelistEmails';
import { getEmailWhitelistInputValue } from '../selectors/whitelistEmailUi';
import { addWhitelistEmail } from '../actions/whitelistEmails';
import { setEmailWhitelistInputValue } from '../actions/whitelistEmailUi';
import EmailWhitelist from '../components/EmailWhitelist';

const mapStateToProps = state => ({
  whitelistEmails: getWhitelistEmailIds(state),
  inputValue: getEmailWhitelistInputValue(state) || ''
});

const mapDispatchToProps = dispatch => ({
  setEmailWhitelistInputValue(event) {
    dispatch(setEmailWhitelistInputValue(event.target.value));
  },
  dispatch
});

const mergeProps = (stateProps, dispatchProps) => Object.assign({}, stateProps, dispatchProps, {
  addWhitelistEmail(event) {
    event.preventDefault();
    dispatchProps.dispatch(addWhitelistEmail(stateProps.inputValue));
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps,
  mergeProps
)(EmailWhitelist);
