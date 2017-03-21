import { connect } from 'react-redux';
import { addLocaleData, IntlProvider } from 'react-intl';
import enLocaleData from 'react-intl/locale-data/en';
import { getLocale, getMessages } from '../../selectors/locale';

addLocaleData(enLocaleData);

const mapStateToProps = (state, ownProps) => ({
  locale: getLocale(state),
  messages: getMessages(state),
  ...ownProps,
});

export default connect(
  mapStateToProps
)(IntlProvider);
