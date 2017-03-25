import { connect } from 'react-redux';
import { scrolledToTop } from '../../actions/pageUi';
import Layout from './Layout';

const mapStateToProps = (state, ownProps) => ({
  shouldScrollToTop: state.pageUi.shouldScrollToTop || false,
  ...ownProps
});

const mapDispatchToProps = dispatch => ({
  scrolledToTop() {
    dispatch(scrolledToTop());
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(Layout);
