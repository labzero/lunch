import { connect } from 'react-redux';
import { removeTag } from '../actions/tags';
import { hideModal } from '../actions/modals';
import DeleteTagModal from '../components/DeleteTagModal';

const modalName = 'deleteTag';

const mapStateToProps = state => ({
  tag: state.tags.items.find(r => r.id === state.modals[modalName].tagId),
  shown: !!state.modals[modalName].shown
});

const mapDispatchToProps = dispatch => ({
  hideModal() {
    dispatch(hideModal(modalName));
  },
  dispatch
});

const mergeProps = (stateProps, dispatchProps) => Object.assign(stateProps, dispatchProps, {
  shown: stateProps.shown && stateProps.tag !== undefined,
  tag: stateProps.tag || {},
  deleteTag(event) {
    event.preventDefault();
    dispatchProps.dispatch(removeTag(stateProps.tag.id));
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps,
  mergeProps
)(DeleteTagModal);
