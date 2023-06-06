import { connect } from "react-redux";
import Footer from "./Footer";
import { State } from "../../interfaces";

const mapStateToProps = (state: State) => ({
  host: state.host,
});

export default connect(mapStateToProps)(Footer);
