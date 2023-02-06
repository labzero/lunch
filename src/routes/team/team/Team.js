import PropTypes from 'prop-types';
/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

import React from 'react';
import withStyles from 'isomorphic-style-loader/withStyles';
import Button from 'react-bootstrap/lib/Button';
import ButtonToolbar from 'react-bootstrap/lib/ButtonToolbar';
import Glyphicon from 'react-bootstrap/lib/Glyphicon';
import Grid from 'react-bootstrap/lib/Grid';
import Tab from 'react-bootstrap/lib/Tab';
import Tabs from 'react-bootstrap/lib/Tabs';
import Table from 'react-bootstrap/lib/Table';
import AddUserFormContainer from '../../../components/AddUserForm/AddUserFormContainer';
import ChangeTeamURLModalContainer from '../../../components/ChangeTeamURLModal/ChangeTeamURLModalContainer';
import DeleteTeamModalContainer from '../../../components/DeleteTeamModal/DeleteTeamModalContainer';
import TeamFormContainer from '../../../components/TeamForm/TeamFormContainer';
import Loading from '../../../components/Loading';
import { globalMessageDescriptor as gm } from '../../../helpers/generateMessageDescriptor';
import getRole from '../../../helpers/getRole';
import canChangeUser from '../../../helpers/canChangeUser';
import s from './Team.scss';

class Team extends React.Component {
  static propTypes = {
    changeTeamURLShown: PropTypes.bool.isRequired,
    changeUserRole: PropTypes.func.isRequired,
    confirm: PropTypes.func.isRequired,
    confirmChangeTeamURL: PropTypes.func.isRequired,
    confirmDeleteTeam: PropTypes.func.isRequired,
    currentUser: PropTypes.object.isRequired,
    deleteTeamShown: PropTypes.bool.isRequired,
    fetchUsersIfNeeded: PropTypes.func.isRequired,
    hasGuestRole: PropTypes.bool.isRequired,
    hasMemberRole: PropTypes.bool.isRequired,
    hasOwnerRole: PropTypes.bool.isRequired,
    intl: PropTypes.shape().isRequired,
    removeUserFromTeam: PropTypes.func.isRequired,
    userListReady: PropTypes.bool.isRequired,
    users: PropTypes.array.isRequired,
    team: PropTypes.object.isRequired,
  };

  componentDidMount() {
    this.props.fetchUsersIfNeeded();
  }

  handleRoleChange = (user) => (event) => {
    const { currentUser, team } = this.props;

    const newRole = event.target.value;

    const changeRole = () => this.props.changeUserRole(user.id, newRole);

    if (
      event.target.value === 'member'
      && getRole(currentUser, team).type === 'member'
    ) {
      this.props.confirm({
        actionLabel: 'Promote',
        body: 'Are you sure you want to promote this user to Member status? You will not be able to demote them later.',
        handleSubmit: changeRole,
      });
    } else if (currentUser.id === user.id && !currentUser.superuser) {
      this.props.confirm({
        actionLabel: 'Demote',
        body: 'Are you sure you want to demote yourself? You will not be able to undo this by yourself.',
        handleSubmit: changeRole,
      });
    } else {
      changeRole();
    }
  };

  handleDeleteUserClicked = (id) => () => {
    // eslint-disable-next-line no-restricted-globals, no-alert
    if (confirm('Are you sure you want to remove this user from this team?')) {
      this.props.removeUserFromTeam(id);
    }
  };

  roleOptions = (user) => {
    const {
      currentUser,
      hasGuestRole,
      hasMemberRole,
      hasOwnerRole,
      intl: { formatMessage: f },
      team,
      users,
    } = this.props;

    if (canChangeUser(currentUser, user, team, users)) {
      return (
        <select onChange={this.handleRoleChange(user)} value={user.type}>
          {hasGuestRole && <option value="guest">{f(gm('guestRole'))}</option>}
          {hasMemberRole && (
            <option value="member">{f(gm('memberRole'))}</option>
          )}
          {hasOwnerRole && <option value="owner">{f(gm('ownerRole'))}</option>}
        </select>
      );
    }
    return f(gm(`${user.type}Role`));
  };

  renderUsers = () => {
    const {
      currentUser,
      hasMemberRole,
      hasOwnerRole,
      intl: { formatMessage: f },
      team,
      users,
    } = this.props;

    return (
      <div>
        <Table responsive>
          <thead>
            <tr>
              <th>Name</th>
              {hasOwnerRole && <th>Email</th>}
              <th>Role</th>
              <th />
            </tr>
          </thead>
          <tbody>
            {users.map((user) => (
              <tr key={user.id}>
                <td>{user.name ? user.name : f(gm('noUserName'))}</td>
                {hasOwnerRole && <td>{user.email}</td>}
                <td>{this.roleOptions(user)}</td>
                <td className={s.deleteCell}>
                  {currentUser.id !== user.id
                    && canChangeUser(currentUser, user, team, users) && (
                      <button
                        className={s.remove}
                        type="button"
                        onClick={this.handleDeleteUserClicked(user.id)}
                        aria-label="Remove"
                      >
                        <Glyphicon glyph="remove" />
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
        <Grid>
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
                  <Button bsStyle="info" onClick={confirmChangeTeamURL}>
                    Change team URL
                  </Button>
                </ButtonToolbar>
                <ButtonToolbar className={s.buttonToolbar}>
                  <Button bsStyle="danger" onClick={confirmDeleteTeam}>
                    Delete team
                  </Button>
                </ButtonToolbar>
              </Tab>
            </Tabs>
          ) : (
            this.renderUsers()
          )}
        </Grid>
        {changeTeamURLShown && <ChangeTeamURLModalContainer />}
        {deleteTeamShown && <DeleteTeamModalContainer />}
      </div>
    );
  }
}

export default withStyles(s)(Team);
