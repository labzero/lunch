import { connect } from "react-redux";
import { scrolledToTop } from "../../actions/pageUi";
import { Dispatch, State } from "../../interfaces";
import Layout from "./Layout";

const mapStateToProps = (state: State, ownProps: { path: string }) => ({
  confirmShown: !!state.modals.confirm,
  shouldScrollToTop: state.pageUi.shouldScrollToTop || false,
  ...ownProps,
});

const mapDispatchToProps = (dispatch: Dispatch) => ({
  scrolledToTop() {
    dispatch(scrolledToTop());
  },
});

export default connect(mapStateToProps, mapDispatchToProps)(Layout);
