import { connect } from 'react-redux';
import { getTagIds } from '../../selectors/tags';
import TagManager from './TagManager';

const mapStateToProps = (state, ownProps) => ({
  tags: getTagIds(state),
  teamSlug: ownProps.teamSlug
});

export default connect(
  mapStateToProps
)(TagManager);
