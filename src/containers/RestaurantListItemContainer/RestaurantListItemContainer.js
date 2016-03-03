import { connect } from 'react-redux';
import RestaurantListItem from '../../components/RestaurantListItem';

const mapStateToProps = (state, ownProps) => {
  const { user } = state;
  return { user, ...ownProps };
};

export default connect(mapStateToProps)(RestaurantListItem);
