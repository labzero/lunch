import { connect } from 'react-redux';
import Tag from '../components/Tag';

const mapStateToProps = (state, ownProps) => ({
  name: ownProps.name || state.tags.items.find(tag => tag.id === ownProps.id).name
});

export default connect(
  mapStateToProps
)(Tag);
