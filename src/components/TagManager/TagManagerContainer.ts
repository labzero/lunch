import { connect } from "react-redux";
import { State } from "../../interfaces";
import { getTagIds } from "../../selectors/tags";
import TagManager from "./TagManager";

const mapStateToProps = (state: State) => ({
  tags: getTagIds(state),
});

export default connect(mapStateToProps)(TagManager);
