import { connect } from 'react-redux';
import { fetchRestaurantsIfNeeded } from '../actions/restaurants';
import HomePage from '../components/HomePage';

const mapStateToProps = state => {
  const { user } = state;
  return { user };
};

const mapDispatchToProps = dispatch => ({
  fetchRestaurantsIfNeeded() {
    dispatch(fetchRestaurantsIfNeeded());
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(HomePage);
