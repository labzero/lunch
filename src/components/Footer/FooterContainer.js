import { connect } from "react-redux";
import Footer from "./Footer";

const mapStateToProps = (state) => ({
  host: state.host,
});

export default connect(mapStateToProps)(Footer);
