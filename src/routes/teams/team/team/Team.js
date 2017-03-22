/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

import React, { PropTypes } from 'react';
import { intlShape } from 'react-intl';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import { globalMessageDescriptor as gm } from '../../../../helpers/generateMessageDescriptor';
import hasRole from '../../../../helpers/hasRole';
import canDeleteUser from '../../../../helpers/canDeleteUser';
import s from './Team.css';

class Team extends React.Component {
  static propTypes = {
    addUserToTeam: PropTypes.func.isRequired,
    currentUser: PropTypes.object.isRequired,
    fetchUsersIfNeeded: PropTypes.func.isRequired,
    intl: intlShape.isRequired,
    removeUserFromTeam: PropTypes.func.isRequired,
    userListReady: PropTypes.bool.isRequired,
    users: PropTypes.array.isRequired,
    team: PropTypes.object.isRequired,
    title: PropTypes.string.isRequired,
  };

  static defaultState = {
    email: '',
    name: '',
    type: 'user'
  };

  state = Object.assign({}, Team.defaultState);

  componentWillMount() {
    this.props.fetchUsersIfNeeded();
  }

  handleChange = field => event => this.setState({ [field]: event.target.value });

  handleSubmit = (event) => {
    event.preventDefault();
    this.props.addUserToTeam(this.state);
    this.setState(Object.assign({}, Team.defaultState));
  };

  handleDeleteClicked = id => () => {
    this.props.removeUserFromTeam(id);
  };

  render() {
    const { userListReady, currentUser, intl: { formatMessage: f }, users, team } = this.props;
    const { email, name, type } = this.state;

    if (!userListReady) {
      return null;
    }

    return (
      <div className={s.root}>
        <div className={s.container}>
          <h1>{this.props.title}</h1>
          <table>
            <thead>
              <tr>
                <th>Name</th>
                <th>Email</th>
                <th>Role</th>
                <th />
              </tr>
            </thead>
            <tbody>
              {users.map(user => (
                <tr key={user.id}>
                  <td>{user.name ? user.name : f(gm('noUserName'))}</td>
                  <td>{user.email}</td>
                  <td>{f(gm(`${user.type}Role`))}</td>
                  <td>
                    {currentUser.id !== user.id && canDeleteUser(currentUser, user, team) && (
                      <button type="button" onClick={this.handleDeleteClicked(user.id)} aria-label="Remove">&times;</button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          <h2>Add User</h2>
          <form onSubmit={this.handleSubmit}>
            <label htmlFor="team-name">
              Name:
            </label>
            <input
              id="team-name"
              type="text"
              onChange={this.handleChange('name')}
              value={name}
            />
            <label htmlFor="team-email">
              Email:
            </label>
            <input
              id="team-email"
              type="email"
              onChange={this.handleChange('email')}
              value={email}
              required
            />
            <label htmlFor="team-type">
              Type:
            </label>
            <select
              id="team-type"
              onChange={this.handleChange('type')}
              value={type}
              required
            >
              {hasRole(currentUser, team, 'user') && <option value="user">{f(gm('userRole'))}</option>}
              {hasRole(currentUser, team, 'admin') && <option value="admin">{f(gm('adminRole'))}</option>}
              {hasRole(currentUser, team, 'owner') && <option value="owner">{f(gm('ownerRole'))}</option>}
            </select>
            <input type="submit" />
          </form>
        </div>
      </div>
    );
  }
}

export default withStyles(s)(Team);
