import React, { Component, PropTypes } from 'react';
import { connect } from 'react-redux';
import { addRestaurant } from '../../actions/restaurants';

class RestaurantAddForm extends Component {

  static propTypes = {
    dispatch: PropTypes.func.isRequired
  }

  handleClick = () => {
    this.props.dispatch(addRestaurant(this._input.value));
    this._input.value = '';
  }

  render() {
    return (
      <form>
        <input ref={node => {this._input = node;}} />
        <button type="button" onClick={this.handleClick}>Add</button>
      </form>
    );
  }
}

function mapStateToProps() {
  return {};
}

export default connect(mapStateToProps)(RestaurantAddForm);
