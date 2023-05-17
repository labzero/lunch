import { connect } from "react-redux";
import HeaderLogin from "./HeaderLogin";

const mapStateToProps = (state) => ({ user: state.user });

export default connect(mapStateToProps)(HeaderLogin);
