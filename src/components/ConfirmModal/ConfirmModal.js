import PropTypes from 'prop-types';
import React from 'react';
import Modal from 'react-bootstrap/Modal';
import ModalBody from 'react-bootstrap/ModalBody';
import ModalFooter from 'react-bootstrap/ModalFooter';
import Button from 'react-bootstrap/Button';

const ConfirmModal = ({
  actionLabel, shown, hideModal, body, handleSubmit
}) => (
  <Modal show={shown} onHide={hideModal}>
    <ModalBody>
      {body}
    </ModalBody>
    <ModalFooter>
      <Button type="button" size="sm" onClick={hideModal} variant="light">Cancel</Button>
      <Button type="button" onClick={handleSubmit} autoFocus size="sm" variant="primary">
        {actionLabel}
      </Button>
    </ModalFooter>
  </Modal>
);

ConfirmModal.propTypes = {
  actionLabel: PropTypes.node.isRequired,
  body: PropTypes.node.isRequired,
  shown: PropTypes.bool.isRequired,
  hideModal: PropTypes.func.isRequired,
  handleSubmit: PropTypes.func.isRequired
};

export default ConfirmModal;
