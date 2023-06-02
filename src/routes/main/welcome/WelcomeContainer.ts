import { ThunkDispatch } from "@reduxjs/toolkit";
import { connect } from "react-redux";
import { updateCurrentUser } from "../../../actions/user";
import history from "../../../history";
import { Action, State, User } from "../../../interfaces";
import { getCurrentUser } from "../../../selectors/user";
import Welcome from "./Welcome";

const mapStateToProps = (state: State) => ({
  host: state.host,
  user: getCurrentUser(state),
});

const mergeProps = (
  stateProps: ReturnType<typeof mapStateToProps>,
  dispatchProps: { dispatch: ThunkDispatch<State, void, Action> },
  ownProps: { next?: string; team?: string }
) => ({
  ...stateProps,
  updateCurrentUser: (payload: Partial<User>) =>
    dispatchProps.dispatch(updateCurrentUser(payload)).then(() => {
      const team = ownProps.team;
      if (team) {
        window.location.href = `//${team}.${stateProps.host}${ownProps.next}`;
      } else if (ownProps.next) {
        history!.push(ownProps.next);
      } else {
        history!.push("/");
      }
    }),
});

export default connect(mapStateToProps, null, mergeProps)(Welcome);
