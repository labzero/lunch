import { connect } from "react-redux";
import FlashComponent from "./Flash";
import { expireFlash } from "../../actions/flash";
import { Dispatch, Flash } from "../../interfaces";

const mapDispatchToProps = (dispatch: Dispatch, ownProps: Flash) => ({
  expireFlash: () => {
    dispatch(expireFlash(ownProps.id));
  },
});

export default connect(null, mapDispatchToProps)(FlashComponent);
