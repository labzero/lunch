import { connect } from 'react-redux';
import { fetchTagsIfNeeded } from '../../../../actions/tags';
import Tags from './Tags';

const mapDispatchToProps = (dispatch, ownProps) => ({
  fetchTagsIfNeeded() {
    dispatch(fetchTagsIfNeeded(ownProps.teamSlug));
  },
});

export default connect(null, mapDispatchToProps)(Tags);
