import { connect } from 'react-redux';
import { showModal } from '../actions/modals';
import Tag from '../components/Tag';

const mapStateToProps = (state, ownProps) => ({
  user: state.user,
  ...ownProps
});

const mapDispatchToProps = (dispatch, ownProps) => ({
  handleClick: () => {
    dispatch(showModal('deleteTag', { tagId: ownProps.id }));
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(Tag);
