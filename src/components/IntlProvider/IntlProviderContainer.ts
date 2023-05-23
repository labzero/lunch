import { connect } from "react-redux";
import { IntlConfig, IntlProvider } from "react-intl";
import { State } from "../../interfaces";
import { getLocale, getMessages } from "../../selectors/locale";

const mapStateToProps = (state: State, ownProps: Partial<IntlConfig>) => ({
  locale: getLocale(state),
  messages: getMessages(state),
  ...ownProps,
});

export default connect(mapStateToProps)(IntlProvider);
