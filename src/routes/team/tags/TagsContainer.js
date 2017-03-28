import { connect } from 'react-redux';
import { fetchTagsIfNeeded } from '../../../actions/tags';
import Tags from './Tags';

const mapDispatchToProps = dispatch => ({
  fetchTagsIfNeeded() {
    dispatch(fetchTagsIfNeeded());
  },
});

export default connect(null, mapDispatchToProps)(Tags);
