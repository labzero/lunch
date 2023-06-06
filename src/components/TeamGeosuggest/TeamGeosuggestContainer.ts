import { connect } from "react-redux";
import { setCenter } from "../../actions/mapUi";
import { Dispatch, LatLng, State } from "../../interfaces";
import { getCenter } from "../../selectors/mapUi";
import TeamGeosuggest, { TeamGeosuggestProps } from "./TeamGeosuggest";

const mapStateToProps = (
  state: State,
  ownProps: Pick<TeamGeosuggestProps, "id" | "initialValue" | "onChange">
) => ({
  center: getCenter(state),
  ...ownProps,
});

const mapDispatchToProps = (dispatch: Dispatch) => ({
  setCenter: (center: LatLng) => dispatch(setCenter(center)),
});

export default connect(mapStateToProps, mapDispatchToProps)(TeamGeosuggest);
