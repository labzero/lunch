import { connect } from "react-redux";
import { fetchTagsIfNeeded } from "../../../actions/tags";
import { Dispatch, State } from "../../../interfaces";
import { isTagListReady } from "../../../selectors";
import Tags from "./Tags";

const mapStateToProps = (state: State) => ({
  tagListReady: isTagListReady(state),
});

const mapDispatchToProps = (dispatch: Dispatch) => ({
  fetchTagsIfNeeded() {
    dispatch(fetchTagsIfNeeded());
  },
});

export default connect<
  ReturnType<typeof mapStateToProps>,
  ReturnType<typeof mapDispatchToProps>,
  { title: string },
  State
>(
  mapStateToProps,
  mapDispatchToProps
)(Tags);
