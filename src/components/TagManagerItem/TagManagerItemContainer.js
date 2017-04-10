import { connect } from 'react-redux';
import { getTagById } from '../../selectors/tags';
import { showModal } from '../../actions/modals';
import { removeTag } from '../../actions/tags';
import TagManagerItem from './TagManagerItem';

const mapStateToProps = (state, ownProps) => ({
  tag: getTagById(state, ownProps.id),
  showDelete: state.user.id !== undefined
});

const mapDispatchToProps = dispatch => ({
  dispatch
});

const mergeProps = (stateProps, dispatchProps, ownProps) =>
  Object.assign({}, stateProps, dispatchProps, {
    handleDeleteClicked() {
      dispatchProps.dispatch(showModal('confirm', {
        actionLabel: 'delete',
        body: `Are you sure you want to delete the “${stateProps.tag.name}” tag?
        All restaurants will be untagged.`,
        handleSubmit: () => dispatchProps.dispatch(removeTag(ownProps.id))
      }));
    }
  });

export default connect(
  mapStateToProps,
  mapDispatchToProps,
  mergeProps
)(TagManagerItem);
