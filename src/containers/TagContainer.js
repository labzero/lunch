import { connect } from 'react-redux';
import Tag from '../components/Tag';

const mapStateToProps = () => {
  let name;
  return (state, ownProps) => {
    if (ownProps.name === undefined) {
      const tag = state.tags.items.find(t => t.id === ownProps.id);
      if (tag !== undefined) {
        name = tag.name;
      }
    } else {
      name = ownProps.name;
    }
    return { name };
  };
};

export default connect(
  mapStateToProps
)(Tag);
