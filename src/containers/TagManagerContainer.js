import { connect } from 'react-redux';
import { showModal } from '../actions/modals';
import TagManager from '../components/TagManager';

const mapStateToProps = state => ({
  tags: state.tags.items,
  showDelete: state.user.id !== undefined
});

const mapDispatchToProps = dispatch => ({
  handleDeleteClicked(id) {
    dispatch(showModal('deleteTag', { tagId: id }));
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(TagManager);
