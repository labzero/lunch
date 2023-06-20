import React, { Component, MouseEvent } from "react";
import withStyles from "isomorphic-style-loader/withStyles";
import Button from "react-bootstrap/Button";
import ListGroup from "react-bootstrap/ListGroup";
import { FaTimes } from "react-icons/fa";
import Container from "react-bootstrap/Container";
import Link from "../../../components/Link/Link";
import { ConfirmOpts, Team, User } from "../../../interfaces";
import s from "./Teams.scss";

interface TeamsProps {
  confirm: (props: ConfirmOpts<"removeUser">) => void;
  host: string;
  teams: Team[];
  user: User;
}

class Teams extends Component<TeamsProps> {
  confirmLeave = (user: User, team: Team) => (event: MouseEvent) => {
    event.preventDefault();
    this.props.confirm({
      actionLabel: "Leave",
      body: `Are you sure you want to leave this team?
You will need to be invited back by another member.`,
      action: "removeUser",
      actionArgs: [user.id, team],
    });
  };

  render() {
    const { host, teams, user } = this.props;

    return (
      <div className={s.root}>
        <Container>
          {teams.length ? (
            <div>
              <h2>Visit one of your teams:</h2>
              <ListGroup className={s.list}>
                {teams.map((team) => (
                  <ListGroup.Item
                    action
                    className={s.item}
                    href={`//${team.slug}.${host}`}
                    key={team.slug}
                  >
                    <div className={s.itemName}>{team.name}</div>
                    <button
                      className={s.leave}
                      onClick={this.confirmLeave(user, team)}
                      aria-label="Leave"
                      type="button"
                    >
                      <FaTimes />
                    </button>
                  </ListGroup.Item>
                ))}
              </ListGroup>
            </div>
          ) : (
            <div className={s.centerer}>
              <h2>You&rsquo;re not currently a part of any teams!</h2>
            </div>
          )}
          <div className={s.centerer}>
            <Link className="btn btn-default" to="/new-team">
              <Button variant="light">Create a new team</Button>
            </Link>
          </div>
        </Container>
      </div>
    );
  }
}

export default withStyles(s)(Teams);
