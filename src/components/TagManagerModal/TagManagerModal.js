import React, { PropTypes } from 'react';
import { Modal, ModalHeader, ModalTitle, ModalBody } from 'react-bootstrap';
import TagManagerContainer from '../../containers/TagManagerContainer';

const TagManagerModal = ({ shown, hideModal }) => (
  <Modal show={shown} onHide={hideModal}>
    <ModalHeader closeButton>
      <ModalTitle>Tag Manager</ModalTitle>
    </ModalHeader>
    <ModalBody>
      <TagManagerContainer />
    </ModalBody>
  </Modal>
);

TagManagerModal.propTypes = {
  shown: PropTypes.bool.isRequired,
  hideModal: PropTypes.func.isRequired,
};

export default TagManagerModal;
