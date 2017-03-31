import React, { PropTypes } from 'react';
import Modal from 'react-bootstrap/lib/Modal';
import ModalBody from 'react-bootstrap/lib/ModalBody';
import ModalFooter from 'react-bootstrap/lib/ModalFooter';
import Button from 'react-bootstrap/lib/Button';

const ConfirmModal = ({ actionLabel, shown, hideModal, body, handleSubmit }) => (
  <Modal show={shown} onHide={hideModal}>
    <ModalBody>
      {body}
    </ModalBody>
    <ModalFooter>
      <Button type="button" bsSize="small" onClick={hideModal}>Cancel</Button>
      <Button type="button" onClick={handleSubmit} autoFocus bsSize="small" bsStyle="primary">
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
