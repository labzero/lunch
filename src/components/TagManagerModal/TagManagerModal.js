import React, { PropTypes } from 'react';
import Modal from 'react-bootstrap/lib/Modal';
import ModalBody from 'react-bootstrap/lib/ModalBody';
import ModalHeader from 'react-bootstrap/lib/ModalHeader';
import ModalTitle from 'react-bootstrap/lib/ModalTitle';
import TagManagerContainer from '../TagManager/TagManagerContainer';

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
