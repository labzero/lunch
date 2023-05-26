import { connect } from "react-redux";
import { getTagById } from "../../selectors/tags";
import { showModal } from "../../actions/modals";
import { removeTag } from "../../actions/tags";
import { Dispatch, State } from "../../interfaces";
import TagManagerItem from "./TagManagerItem";

interface OwnProps {
  id: number;
}

const mapStateToProps = (state: State, ownProps: OwnProps) => ({
  tag: getTagById(state, ownProps.id),
  showDelete: state.user !== null,
});

const mapDispatchToProps = (dispatch: Dispatch) => ({
  dispatch,
});

const mergeProps = (
  stateProps: ReturnType<typeof mapStateToProps>,
  dispatchProps: ReturnType<typeof mapDispatchToProps>,
  ownProps: OwnProps
) => ({
  ...stateProps,
  ...dispatchProps,
  handleDeleteClicked() {
    dispatchProps.dispatch(
      showModal("confirm", {
        actionLabel: "Delete",
        body: `Are you sure you want to delete the “${stateProps.tag.name}” tag?
        All restaurants will be untagged.`,
        action: removeTag(ownProps.id),
      })
    );
  },
});

export default connect(
  mapStateToProps,
  mapDispatchToProps,
  mergeProps
)(TagManagerItem);
