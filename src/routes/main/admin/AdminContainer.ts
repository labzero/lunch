import { connect } from "react-redux";
import { State } from "../../../interfaces";
import Admin from "./Admin";

const mapStateToProps = (state: State) => ({
  host: state.host,
});

export default connect(mapStateToProps)(Admin);
