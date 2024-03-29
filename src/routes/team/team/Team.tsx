/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

import React, { ChangeEvent } from "react";
import withStyles from "isomorphic-style-loader/withStyles";
import Button from "react-bootstrap/Button";
import ButtonToolbar from "react-bootstrap/ButtonToolbar";
import { FaTimes } from "react-icons/fa";
import Container from "react-bootstrap/Container";
import Tab from "react-bootstrap/Tab";
import Tabs from "react-bootstrap/Tabs";
import Table from "react-bootstrap/Table";
import Loading from "../../../components/Loading/Loading";
import AddUserFormContainer from "../../../components/AddUserForm/AddUserFormContainer";
import ChangeTeamURLModalContainer from "../../../components/ChangeTeamURLModal/ChangeTeamURLModalContainer";
import DeleteTeamModalContainer from "../../../components/DeleteTeamModal/DeleteTeamModalContainer";
import TeamFormContainer from "../../../components/TeamForm/TeamFormContainer";
import getRole from "../../../helpers/getRole";
import canChangeUser from "../../../helpers/canChangeUser";
import {
  User,
  Team as TeamType,
  ConfirmOpts,
  Action,
  RoleType,
} from "../../../interfaces";
import s from "./Team.scss";

interface TeamProps {
  changeTeamURLShown: boolean;
  changeUserRole: (userId: number, role: string) => Action;
  confirm: (options: ConfirmOpts<"changeUserRole">) => void;
  confirmChangeTeamURL: () => void;
  confirmDeleteTeam: () => void;
  currentUser: User;
  deleteTeamShown: boolean;
  dispatch: (action: Action) => void;
  fetchUsersIfNeeded: () => void;
  hasGuestRole: boolean;
  hasMemberRole: boolean;
  hasOwnerRole: boolean;
  removeUserFromTeam: (userId: number) => void;
  userListReady: boolean;
  users: User[];
  team: TeamType;
}

class Team extends React.Component<TeamProps> {
  componentDidMount() {
    this.props.fetchUsersIfNeeded();
  }

  handleRoleChange =
    (user: User) => (event: ChangeEvent<HTMLSelectElement>) => {
      const { currentUser, team } = this.props;

      const newRole = event.currentTarget.value as RoleType;

      if (
        event.currentTarget.value === "member" &&
        getRole(currentUser, team)?.type === "member"
      ) {
        this.props.confirm({
          actionLabel: "Promote",
          body: "Are you sure you want to promote this user to Member status? You will not be able to demote them later.",
          action: "changeUserRole",
          actionArgs: [user.id, newRole],
        });
      } else if (currentUser.id === user.id && !currentUser.superuser) {
        this.props.confirm({
          actionLabel: "Demote",
          body: "Are you sure you want to demote yourself? You will not be able to undo this by yourself.",
          action: "changeUserRole",
          actionArgs: [user.id, newRole],
        });
      } else {
        const changeRole = this.props.changeUserRole(user.id, newRole);
        this.props.dispatch(changeRole);
      }
    };

  handleDeleteUserClicked = (id: number) => () => {
    // eslint-disable-next-line no-restricted-globals, no-alert
    if (confirm("Are you sure you want to remove this user from this team?")) {
      this.props.removeUserFromTeam(id);
    }
  };

  roleOptions = (user: User) => {
    const {
      currentUser,
      hasGuestRole,
      hasMemberRole,
      hasOwnerRole,
      team,
      users,
    } = this.props;

    if (canChangeUser(currentUser, user, team, users)) {
      return (
        <select onInput={this.handleRoleChange(user)} value={user.type}>
          {hasGuestRole && <option value="guest">Guest</option>}
          {hasMemberRole && <option value="member">Member</option>}
          {hasOwnerRole && <option value="owner">Owner</option>}
        </select>
      );
    }
    return user.type
      ? user.type.charAt(0).toUpperCase() + user.type.slice(1)
      : "";
  };

  renderUsers = () => {
    const { currentUser, hasMemberRole, hasOwnerRole, team, users } =
      this.props;

    return (
      <div>
        <Table responsive>
          <thead>
            <tr>
              <th>Name</th>
              {hasOwnerRole && <th>Email</th>}
              <th>Role</th>
              {/* eslint-disable-next-line jsx-a11y/control-has-associated-label */}
              <th />
            </tr>
          </thead>
          <tbody>
            {users.map((user) => (
              <tr key={user.id}>
                <td>{user.name}</td>
                {hasOwnerRole && <td>{user.email}</td>}
                <td>{this.roleOptions(user)}</td>
                <td className={s.deleteCell}>
                  {currentUser.id !== user.id &&
                    canChangeUser(currentUser, user, team, users) && (
                      <button
                        className={s.remove}
                        type="button"
                        onClick={this.handleDeleteUserClicked(user.id)}
                        aria-label="Remove"
                      >
                        <FaTimes />
                      </button>
                    )}
                </td>
              </tr>
            ))}
          </tbody>
        </Table>
        {hasMemberRole && <AddUserFormContainer />}
      </div>
    );
  };

  render() {
    const {
      changeTeamURLShown,
      confirmChangeTeamURL,
      confirmDeleteTeam,
      deleteTeamShown,
      hasOwnerRole,
      team,
      userListReady,
    } = this.props;

    if (!userListReady) {
      return <Loading />;
    }

    return (
      <div className={s.root}>
        <Container>
          <h2>{team.name}</h2>
          {hasOwnerRole ? (
            <Tabs id="team-tabs" mountOnEnter>
              <Tab eventKey={1} title="Users">
                <h3>User List</h3>
                {this.renderUsers()}
              </Tab>
              <Tab eventKey={2} title="Team">
                <h3>Team Management</h3>
                <TeamFormContainer />
              </Tab>
              <Tab eventKey={3} title="Messy Business">
                <h3>Messy Business</h3>
                <ButtonToolbar className={s.buttonToolbar}>
                  <Button variant="info" onClick={confirmChangeTeamURL}>
                    Change team URL
                  </Button>
                </ButtonToolbar>
                <ButtonToolbar className={s.buttonToolbar}>
                  <Button variant="danger" onClick={confirmDeleteTeam}>
                    Delete team
                  </Button>
                </ButtonToolbar>
              </Tab>
            </Tabs>
          ) : (
            this.renderUsers()
          )}
        </Container>
        {changeTeamURLShown && <ChangeTeamURLModalContainer />}
        {deleteTeamShown && <DeleteTeamModalContainer />}
      </div>
    );
  }
}

export default withStyles(s)(Team);
