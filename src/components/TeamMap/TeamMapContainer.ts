import { MapStateToProps, connect } from "react-redux";
import { clearCenter, setCenter } from "../../actions/mapUi";
import { Dispatch, LatLng, State } from "../../interfaces";
import { getCenter } from "../../selectors/mapUi";
import TeamMap, { TeamMapProps } from "./TeamMap";

const mapStateToProps: MapStateToProps<
  { center?: LatLng },
  Pick<TeamMapProps, "defaultCenter">,
  State
> = (state) => ({
  center: getCenter(state),
});

const mapDispatchToProps = (dispatch: Dispatch) => ({
  clearCenter: () => dispatch(clearCenter()),
  setCenter: (center: LatLng) => dispatch(setCenter(center)),
});

export default connect(mapStateToProps, mapDispatchToProps)(TeamMap);
