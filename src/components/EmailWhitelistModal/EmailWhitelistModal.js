import React, { PropTypes } from 'react';
import Modal from 'react-bootstrap/lib/Modal';
import ModalBody from 'react-bootstrap/lib/ModalBody';
import ModalHeader from 'react-bootstrap/lib/ModalHeader';
import ModalTitle from 'react-bootstrap/lib/ModalTitle';
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
