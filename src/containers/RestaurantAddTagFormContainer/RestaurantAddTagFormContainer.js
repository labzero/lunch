import { connect } from 'react-redux';
import { hideAddTagForm } from '../../actions/restaurants';
import RestaurantAddTagForm from '../../components/RestaurantAddTagForm';

const mapStateToProps = (state, ownProps) => ownProps;

const mapDispatchToProps = (dispatch, ownProps) => ({
  hideAddTagForm() {
    dispatch(hideAddTagForm(ownProps.id));
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(RestaurantAddTagForm);
