import { connect } from 'react-redux';
import App from '../../components/App';

const mapStateToProps = null;

const mapDispatchToProps = dispatch => ({
  messageReceived(event) {
  console.log(event.data);
    try {
      const data = JSON.parse(event.data);
      dispatch(data);
    } catch (SyntaxError) {
      console.log('Couldn\'t parse message data.');
    }
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(App);
