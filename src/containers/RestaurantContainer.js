import { connect } from 'react-redux';
import { showAddTagForm } from '../actions/listUi';
import Restaurant from '../components/Restaurant';

const mapStateToProps = (state, ownProps) => ({
  user: state.user,
  listUiItem: state.listUi[ownProps.id] || {},
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
