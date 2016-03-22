import React, { PropTypes } from 'react';
import { Modal } from 'react-bootstrap';

const TagManagerModal = ({ shown, hideModal }) => (
  <Modal show={shown} onHide={hideModal}>
    <Modal.Header closeButton>
      <Modal.Title>Tag Manager</Modal.Title>
    </Modal.Header>
    <Modal.Body>
      Hi!
    </Modal.Body>
  </Modal>
);

TagManagerModal.propTypes = {
  shown: PropTypes.bool.isRequired,
  hideModal: PropTypes.func.isRequired,
};

export default TagManagerModal;
