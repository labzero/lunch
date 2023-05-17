import { connect } from "react-redux";
import TeamGeosuggest from "./TeamGeosuggest";
import { setCenter } from "../../actions/mapUi";
import { getCenter } from "../../selectors/mapUi";

const mapStateToProps = (state, ownProps) => ({
  center: getCenter(state),
  ...ownProps,
});

const mapDispatchToProps = (dispatch) => ({
  setCenter: (center) => dispatch(setCenter(center)),
});

export default connect(mapStateToProps, mapDispatchToProps)(TeamGeosuggest);
