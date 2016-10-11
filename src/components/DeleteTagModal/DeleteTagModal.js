import React, { PropTypes } from 'react';
import { Modal, ModalBody, ModalFooter, Button } from 'react-bootstrap';

const DeleteTagModal = ({ tagName, shown, hideModal, deleteTag }) => (
  <Modal show={shown} onHide={hideModal}>
    <ModalBody>
      Are you sure you want to delete the &ldquo;{tagName}&rdquo; tag?
      All restaurants will be untagged.
    </ModalBody>
    <ModalFooter>
      <form onSubmit={deleteTag}>
        <Button type="button" bsSize="small" onClick={hideModal}>Cancel</Button>
        <Button type="submit" autoFocus bsSize="small" bsStyle="primary">Delete</Button>
      </form>
    </ModalFooter>
  </Modal>
);

DeleteTagModal.propTypes = {
  tagName: PropTypes.string.isRequired,
  shown: PropTypes.bool.isRequired,
  hideModal: PropTypes.func.isRequired,
  deleteTag: PropTypes.func.isRequired
};

export default DeleteTagModal;
