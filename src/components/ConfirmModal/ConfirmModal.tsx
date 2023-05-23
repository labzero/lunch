import React, { ReactNode } from "react";
import Modal from "react-bootstrap/Modal";
import ModalBody from "react-bootstrap/ModalBody";
import ModalFooter from "react-bootstrap/ModalFooter";
import Button from "react-bootstrap/Button";

export interface ConfirmModalProps {
  actionLabel: string;
  shown: boolean;
  hideModal: () => void;
  body: ReactNode;
  handleSubmit: () => void;
}

const ConfirmModal = ({
  actionLabel,
  shown,
  hideModal,
  body,
  handleSubmit,
}: ConfirmModalProps) => (
  <Modal show={shown} onHide={hideModal}>
    <ModalBody>{body}</ModalBody>
    <ModalFooter>
      <Button type="button" size="sm" onClick={hideModal} variant="light">
        Cancel
      </Button>
      <Button
        type="button"
        onClick={handleSubmit}
        autoFocus
        size="sm"
        variant="primary"
      >
        {actionLabel}
      </Button>
    </ModalFooter>
  </Modal>
);

export default ConfirmModal;
