import React, { ChangeEvent, Component, TargetedEvent } from "react";
import withStyles from "isomorphic-style-loader/withStyles";
import Button from "react-bootstrap/Button";
import Col from "react-bootstrap/Col";
import Form from "react-bootstrap/Form";
import Container from "react-bootstrap/Container";
import InputGroup from "react-bootstrap/InputGroup";
import Row from "react-bootstrap/Row";
import { TEAM_SLUG_REGEX } from "../../../constants";
import defaultCoords from "../../../constants/defaultCoords";
import TeamGeosuggestContainer from "../../../components/TeamGeosuggest/TeamGeosuggestContainer";
import TeamMapContainer from "../../../components/TeamMap/TeamMapContainer";
import history from "../../../history";
import { LatLng, Team } from "../../../interfaces";
import s from "./NewTeam.scss";

interface NewTeamProps {
  center?: LatLng;
  createTeam: (team: Partial<Team>) => Promise<void>;
}

interface NewTeamState {
  name?: string;
  slug?: string;
  address?: string;
}

class NewTeam extends Component<NewTeamProps, NewTeamState> {
  static defaultProps = {
    center: defaultCoords,
  };

  constructor(props: NewTeamProps) {
    super(props);

    this.state = {
      name: "",
      slug: "",
      address: "",
    };
  }

  handleGeosuggestChange = (value: string) => this.setState({ address: value });

  handleChange =
    (field: keyof NewTeamState) =>
    (event: ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) =>
      this.setState({ [field]: event.currentTarget.value });

  handleSlugChange = (
    event: ChangeEvent<HTMLInputElement | HTMLTextAreaElement>
  ) => {
    this.setState({
      slug: event.currentTarget.value.toLowerCase(),
    });
  };

  handleSubmit = (event: TargetedEvent) => {
    const { center, createTeam } = this.props;

    event.preventDefault();

    createTeam({
      ...center,
      ...this.state,
    }).then(() => history?.push("/teams"));
  };

  render() {
    const { name, slug } = this.state;

    return (
      <div className={s.root}>
        <Container>
          <h2>Create a new team</h2>
          <form onSubmit={this.handleSubmit}>
            <Form.Group className="mb-3" controlId="newTeam-name">
              <Form.Label>Name</Form.Label>
              <Row>
                <Col sm={6}>
                  <Form.Control
                    type="text"
                    onChange={this.handleChange("name")}
                    value={name}
                    required
                  />
                </Col>
              </Row>
            </Form.Group>
            <Form.Group className="mb-3" controlId="newTeam-slug">
              <Form.Label>URL</Form.Label>
              <Row>
                <Col sm={6}>
                  <InputGroup>
                    <Form.Control
                      autoCorrect="off"
                      autoCapitalize="off"
                      className={s.teamUrl}
                      type="text"
                      value={slug}
                      maxLength={63}
                      minLength={2}
                      pattern={TEAM_SLUG_REGEX}
                      onChange={this.handleSlugChange}
                      required
                    />
                    <InputGroup.Text>.lunch.pink</InputGroup.Text>
                  </InputGroup>
                </Col>
              </Row>
              <Form.Text>
                Letters, numbers, and dashes only. URL must start with a letter.
              </Form.Text>
            </Form.Group>
            <Form.Group className="mb-3" controlId="newTeam-address">
              <Form.Label>Address</Form.Label>
              <p>
                Pick a centerpoint for your team. It will ensure that nearby
                recommendations are shown when you search for restaurants. You
                can drag the map or enter your full address.
              </p>
              <TeamMapContainer defaultCenter={defaultCoords} />
              <TeamGeosuggestContainer
                id="newTeam-address"
                initialValue=""
                onChange={this.handleGeosuggestChange}
              />
            </Form.Group>
            <Button type="submit">Submit</Button>
          </form>
        </Container>
      </div>
    );
  }
}

export default withStyles(s)(NewTeam);
