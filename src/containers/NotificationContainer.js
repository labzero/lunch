import { connect } from 'react-redux';
import Notification from '../components/Notification';
import { expireNotification } from '../actions/notifications';

const mapStateToProps = (state, ownProps) => {
  const { vals } = ownProps;
  if (vals.userId === state.user.id) {
    return { noRender: true };
  }
  const dict = {
    loggedIn: state.user.id !== undefined,
    restaurant: vals.restaurantId ? state.restaurants.items.find(r => r.id === vals.restaurantId).name : undefined
  };
  if (dict.loggedIn) {
    dict.user = vals.userId ? state.users.items.find(u => u.id === vals.userId).name : undefined;
  }
  return {
    actionType: ownProps.actionType,
    dict
  };
};

const mapDispatchToProps = (dispatch, ownProps) => ({
  expireNotification() {
    dispatch(expireNotification(ownProps.id));
  }
});

export default connect(mapStateToProps, mapDispatchToProps)(Notification);
