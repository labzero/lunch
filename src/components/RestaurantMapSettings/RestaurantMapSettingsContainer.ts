import { ChangeEvent } from "react";
import { connect } from "react-redux";
import { flashSuccess } from "../../actions/flash";
import { setShowPOIs, setShowUnvoted } from "../../actions/mapUi";
import { updateTeam } from "../../actions/team";
import { Dispatch, State } from "../../interfaces";
import RestaurantMapSettings from "./RestaurantMapSettings";

const mapStateToProps = (state: State) => ({
  showPOIs: state.mapUi.showPOIs,
  showUnvoted: state.mapUi.showUnvoted,
});

const mapDispatchToProps = (
  dispatch: Dispatch,
  ownProps: { map: google.maps.Map }
) => ({
  setDefaultZoom: () =>
    dispatch(updateTeam({ defaultZoom: ownProps.map.getZoom() })).then(() =>
      dispatch(flashSuccess("Default zoom level set for team."))
    ),
  setShowUnvoted: (event: ChangeEvent<HTMLInputElement>) =>
    dispatch(setShowUnvoted(event.currentTarget.checked)),
  setShowPOIs: (event: ChangeEvent<HTMLInputElement>) =>
    dispatch(setShowPOIs(event.currentTarget.checked)),
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(RestaurantMapSettings);
