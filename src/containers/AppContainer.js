import { connect } from 'react-redux';
import { scrolledToTop } from '../actions/pageUi';
import App from '../components/App';

const mapStateToProps = (state, ownProps) => ({
  modals: state.modals,
  wsPort: state.wsPort,
  shouldScrollToTop: state.pageUi.shouldScrollToTop || false,
  ...ownProps
});

const mapDispatchToProps = dispatch => ({
  messageReceived(event) {
    try {
      const data = JSON.parse(event.data);
      dispatch(data);
    } catch (SyntaxError) {
      // console.error('Couldn\'t parse message data.');
    }
  },
  scrolledToTop() {
    dispatch(scrolledToTop());
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(App);
