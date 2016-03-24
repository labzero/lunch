import React, { PropTypes, Component } from 'react';
import { Modal, Button } from 'react-bootstrap';

class DeleteTagModal extends Component {
  state = {};

  componentWillMount() {
    // set state in case tag is deleted and tag disappears
    this.setState({
      tagName: this.props.tag.name
    });
  }

  componentWillReceiveProps(nextProps) {
    if (nextProps.tag.name !== undefined && nextProps.tag.name !== this.state.tagName) {
      this.setState({
        tagName: nextProps.tag.name
      });
    }
  }

  render() {
    return (
      <Modal show={this.props.shown} onHide={this.props.hideModal}>
        <Modal.Body>
          Are you sure you want to delete the "{this.state.tagName}" tag?
          All restaurants will be untagged.
        </Modal.Body>
        <Modal.Footer>
          <form onSubmit={this.props.deleteTag}>
            <Button type="button" bsSize="small" onClick={this.props.hideModal}>Cancel</Button>
            <Button type="submit" autoFocus bsSize="small" bsStyle="primary">Delete</Button>
          </form>
        </Modal.Footer>
      </Modal>
    );
  }
}

DeleteTagModal.propTypes = {
  tag: PropTypes.object.isRequired,
  shown: PropTypes.bool.isRequired,
  hideModal: PropTypes.func.isRequired,
  deleteTag: PropTypes.func.isRequired
};

export default DeleteTagModal;
