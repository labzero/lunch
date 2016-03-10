import { connect } from 'react-redux';
import { showAddTagForm } from '../../actions/restaurants';
import Restaurant from '../../components/Restaurant';

const mapStateToProps = (state, ownProps) => ({
  user: state.user,
  ...ownProps
});

const mapDispatchToProps = (dispatch, ownProps) => ({
  showAddTagForm() {
    dispatch(showAddTagForm(ownProps.id));
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(Restaurant);
