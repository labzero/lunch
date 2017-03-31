import { connect } from 'react-redux';
import { fetchTagsIfNeeded } from '../../../actions/tags';
import { isTagListReady } from '../../../selectors';
import Tags from './Tags';

const mapStateToProps = state => ({
  tagListReady: isTagListReady(state),
});

const mapDispatchToProps = dispatch => ({
  fetchTagsIfNeeded() {
    dispatch(fetchTagsIfNeeded());
  },
});

export default connect(mapStateToProps, mapDispatchToProps)(Tags);
