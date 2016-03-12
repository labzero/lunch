import { connect } from 'react-redux';
import { removeVote, addVote } from '../actions/restaurants';
import RestaurantVoteButton from '../components/RestaurantVoteButton';

const mapStateToProps = (state, ownProps) => ({
  ...ownProps,
  user: state.user
});

const mapDispatchToProps = null;

const mergeProps = (stateProps, dispatchProps, ownProps) => Object.assign({}, stateProps, dispatchProps, {
  handleClick: () => {
    let votesDeleted = false;
    ownProps.votes.forEach(vote => {
      if (vote.user_id === stateProps.user.id) {
        votesDeleted = true;
        dispatchProps.dispatch(removeVote(ownProps.id, vote.id));
      }
    });
    if (!votesDeleted) {
      dispatchProps.dispatch(addVote(ownProps.id));
    }
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps,
  mergeProps
)(RestaurantVoteButton);
