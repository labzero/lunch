import React, { PropTypes } from 'react';
import Modal from 'react-bootstrap/lib/Modal';
import ModalBody from 'react-bootstrap/lib/ModalBody';
import ModalFooter from 'react-bootstrap/lib/ModalFooter';
import Button from 'react-bootstrap/lib/Button';

const DeleteRestaurantModal = ({ shown, hideModal, restaurantName, deleteRestaurant }) => (
  <Modal show={shown} onHide={hideModal}>
    <ModalBody>
      Are you sure you want to delete {restaurantName}?
    </ModalBody>
    <ModalFooter>
      <form onSubmit={deleteRestaurant}>
        <Button type="button" bsSize="small" onClick={hideModal}>Cancel</Button>
        <Button type="submit" autoFocus bsSize="small" bsStyle="primary">Delete</Button>
      </form>
    </ModalFooter>
  </Modal>
);

DeleteRestaurantModal.propTypes = {
  restaurantName: PropTypes.string.isRequired,
  shown: PropTypes.bool.isRequired,
  hideModal: PropTypes.func.isRequired,
  deleteRestaurant: PropTypes.func.isRequired
};

export default DeleteRestaurantModal;
