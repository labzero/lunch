import { connect } from 'react-redux';
import { getTagById } from '../selectors/tags';
import { showModal } from '../actions/modals';
import TagManagerItem from '../components/TagManagerItem';

const mapStateToProps = (state, ownProps) => ({
  tag: getTagById(state, ownProps.id),
  showDelete: state.user.id !== undefined
});

const mapDispatchToProps = (dispatch, ownProps) => ({
  handleDeleteClicked() {
    dispatch(showModal('deleteTag', { tagId: ownProps.id }));
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(TagManagerItem);
