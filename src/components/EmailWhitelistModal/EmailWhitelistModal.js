import React, { PropTypes } from 'react';
import { Modal, ModalHeader, ModalTitle, ModalBody } from 'react-bootstrap';
import EmailWhitelistContainer from '../../containers/EmailWhitelistContainer';

const EmailWhitelistModal = ({ shown, hideModal }) => (
  <Modal show={shown} onHide={hideModal}>
    <ModalHeader closeButton>
      <ModalTitle>Email Whitelist</ModalTitle>
    </ModalHeader>
    <ModalBody>
      <EmailWhitelistContainer />
    </ModalBody>
  </Modal>
);

EmailWhitelistModal.propTypes = {
  shown: PropTypes.bool.isRequired,
  hideModal: PropTypes.func.isRequired,
};

export default EmailWhitelistModal;
