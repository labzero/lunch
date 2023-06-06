import { connect } from "react-redux";
import { State } from "../../interfaces";
import HeaderLogin from "./HeaderLogin";

const mapStateToProps = (state: State) => ({ user: state.user });

export default connect(mapStateToProps)(HeaderLogin);
