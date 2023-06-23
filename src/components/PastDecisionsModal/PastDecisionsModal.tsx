import React, { ChangeEvent, Component } from "react";
import Form from "react-bootstrap/Form";
import Modal from "react-bootstrap/Modal";
import ModalBody from "react-bootstrap/ModalBody";
import ModalHeader from "react-bootstrap/ModalHeader";
import ModalFooter from "react-bootstrap/ModalFooter";
import Button from "react-bootstrap/Button";
import { Action, Decision, Restaurant } from "../../interfaces";

export interface PastDecisionsModalProps {
  decide: (daysAgo: number) => Promise<Action>;
  decisionsByDay: { [key: number]: Decision[] };
  hideModal: () => void;
  restaurantEntities: { [key: number]: Restaurant };
  shown: boolean;
}

interface PastDecisionsModalState {
  daysAgo: number;
}

class PastDecisionsModal extends Component<
  PastDecisionsModalProps,
  PastDecisionsModalState
> {
  constructor(props: PastDecisionsModalProps) {
    super(props);

    this.state = {
      daysAgo: 0,
    };
  }

  handleChange = (event: ChangeEvent<HTMLSelectElement>) =>
    this.setState({
      daysAgo: Number(event.currentTarget.value),
    });

  handleSubmit = () => {
    const { decide } = this.props;
    const { daysAgo } = this.state;

    decide(daysAgo).then(() => this.setState({ daysAgo: 0 }));
  };

  renderOption(index: number, text?: string) {
    const { decisionsByDay, restaurantEntities } = this.props;

    let children = text || `${index} days ago`;
    let disabled = false;
    if (index > 0 && decisionsByDay[index].length > 0) {
      const decisionNamesForDay = decisionsByDay[index]
        .reduce<string[]>((acc, curr) => {
          const restaurant = restaurantEntities[curr.restaurantId];
          if (restaurant) {
            disabled = true;
            acc.push(restaurant.name);
          }
          return acc;
        }, [])
        .join(", ");
      children = `${children} (${decisionNamesForDay})`;
    }

    return (
      <option disabled={disabled} value={index}>
        {children}
      </option>
    );
  }

  render() {
    const { shown, hideModal } = this.props;
    const { daysAgo } = this.state;

    return (
      <Modal show={shown} onHide={hideModal}>
        <ModalHeader>We ate here...</ModalHeader>
        <ModalBody>
          <Form.Select onChange={this.handleChange} value={daysAgo} required>
            {this.renderOption(0, "Today")}
            {this.renderOption(1, "Yesterday")}
            {this.renderOption(2)}
            {this.renderOption(3)}
            {this.renderOption(4)}
          </Form.Select>
        </ModalBody>
        <ModalFooter>
          <Button size="sm" onClick={hideModal} variant="light">
            Cancel
          </Button>
          <Button
            autoFocus
            size="sm"
            variant="primary"
            onClick={this.handleSubmit}
            type="submit"
          >
            Decide
          </Button>
        </ModalFooter>
      </Modal>
    );
  }
}

export default PastDecisionsModal;
