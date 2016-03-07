import { connect } from 'react-redux';
import { addVote } from '../../actions/restaurants';
import RestaurantVoteButton from '../../components/RestaurantVoteButton';

const mapStateToProps = (state, ownProps) => ({
  
});

const mapDispatchToProps = (dispatch, ownProps) => ({
  handleClick: () => {
    dispatch(removeRestaurant(ownProps.id));
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(RestaurantVoteButton);
