import { connect } from 'react-redux';
import Restaurant from '../../components/Restaurant';

const mapStateToProps = (state, ownProps) => {
  const { user } = state;
  return { user, ...ownProps };
};

export default connect(mapStateToProps)(Restaurant);
