import { connect } from 'react-redux';
import { removeTag } from '../actions/tags';
import Tag from '../components/Tag';

const mapStateToProps = (state, ownProps) => ({
  user: state.user,
  ...ownProps
});

const mapDispatchToProps = (dispatch, ownProps) => ({
  handleClick: () => {
    dispatch(removeTag(ownProps.id));
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(Tag);
