import React, { PropTypes, Component } from 'react';
import { Modal, ModalBody, ModalFooter, Button } from 'react-bootstrap';

class DeleteRestaurantModal extends Component {
  state = {};

  componentWillMount() {
    // set state in case restaurant is deleted and restaurant disappears
    this.setState({
      restaurantName: this.props.restaurant.name
    });
  }

  componentWillReceiveProps(nextProps) {
    if (nextProps.restaurant.name !== undefined && nextProps.restaurant.name !== this.state.restaurantName) {
      this.setState({
        restaurantName: nextProps.restaurant.name
      });
    }
  }

  render() {
    return (
      <Modal show={this.props.shown} onHide={this.props.hideModal}>
        <ModalBody>
          Are you sure you want to delete {this.state.restaurantName}?
        </ModalBody>
        <ModalFooter>
          <form onSubmit={this.props.deleteRestaurant}>
            <Button type="button" bsSize="small" onClick={this.props.hideModal}>Cancel</Button>
            <Button type="submit" autoFocus bsSize="small" bsStyle="primary">Delete</Button>
          </form>
        </ModalFooter>
      </Modal>
    );
  }
}

DeleteRestaurantModal.propTypes = {
  restaurant: PropTypes.object.isRequired,
  shown: PropTypes.bool.isRequired,
  hideModal: PropTypes.func.isRequired,
  deleteRestaurant: PropTypes.func.isRequired
};

export default DeleteRestaurantModal;
