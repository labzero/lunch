import { connect } from "react-redux";
import { flashSuccess } from "../../../actions/flash";
import { updateCurrentUser } from "../../../actions/user";
import { getCurrentUser } from "../../../selectors/user";
import Account from "./Account";

const mapStateToProps = (state) => ({
  user: getCurrentUser(state),
});

const mapDispatchToProps = (dispatch) => ({
  updateCurrentUser: (payload) =>
    dispatch(updateCurrentUser(payload)).then(() =>
      dispatch(flashSuccess("Account details updated."))
    ),
});

export default connect(mapStateToProps, mapDispatchToProps)(Account);
