import { connect } from 'react-redux';
import TagManager from '../components/TagManager';

const mapStateToProps = state => ({
  tags: state.tags.items
});

export default connect(
  mapStateToProps
)(TagManager);
