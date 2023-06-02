import { connect } from "react-redux";
import { flashSuccess } from "../../../actions/flash";
import { updateCurrentUser } from "../../../actions/user";
import { Dispatch, State, User } from "../../../interfaces";
import { getCurrentUser } from "../../../selectors/user";
import Account from "./Account";

const mapStateToProps = (state: State) => ({
  user: getCurrentUser(state),
});

const mapDispatchToProps = (dispatch: Dispatch) => ({
  updateCurrentUser: (payload: Partial<User>) =>
    dispatch(updateCurrentUser(payload)).then(() =>
      dispatch(flashSuccess("Account details updated."))
    ),
});

export default connect(mapStateToProps, mapDispatchToProps)(Account);
