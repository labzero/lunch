import { connect } from 'react-redux';
import { getTagIds } from '../selectors/tags';
import TagManager from '../components/TagManager';

const mapStateToProps = state => ({
  tags: getTagIds(state)
});

export default connect(
  mapStateToProps
)(TagManager);
