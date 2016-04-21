import { connect } from 'react-redux';
import { getDecision } from '../selectors/decisions';
import { decide } from '../actions/decisions';
import RestaurantDecision from '../components/RestaurantDecision';

const mapStateToProps = (state, ownProps) => {
  const decision = getDecision(state);
  return {
    loggedIn: state.user.id !== undefined,
    decided: decision !== null && decision.restaurant_id === ownProps.id,
    restaurantId: ownProps.id
  };
};

const mapDispatchToProps = (dispatch, ownProps) => ({
  handleClick() {
    dispatch(decide(ownProps.id));
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(RestaurantDecision);
