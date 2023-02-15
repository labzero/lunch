import { connect } from 'react-redux';
import { IntlProvider } from 'react-intl';
import { getLocale, getMessages } from '../../selectors/locale';

const mapStateToProps = (state, ownProps) => ({
  locale: getLocale(state),
  messages: getMessages(state),
  ...ownProps,
});

export default connect(mapStateToProps)(IntlProvider);
