import { connect } from 'react-redux';
import { getWhitelistEmailIds } from '../selectors/whitelistEmails';
import EmailWhitelist from '../components/EmailWhitelist';

const mapStateToProps = state => ({
  whitelistEmails: getWhitelistEmailIds(state)
});

export default connect(
  mapStateToProps
)(EmailWhitelist);
