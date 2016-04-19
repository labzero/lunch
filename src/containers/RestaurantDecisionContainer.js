import { connect } from 'react-redux';
import { getDecision } from '../selectors/decisions';
import RestaurantDecision from '../components/RestaurantDecision';

const mapStateToProps = (state, ownProps) => {
  const decision = getDecision(state);
  return {
    decided: decision !== null && decision.restaurant_id === ownProps.id,
    restaurantId: ownProps.id
  };
};

const mapDispatchToProps = (dispatch, ownProps) => ({
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(RestaurantDecision);
