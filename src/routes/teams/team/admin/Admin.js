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
import s from './Admin.css';

class Admin extends React.Component {
  static propTypes = {
    addUserToTeam: PropTypes.func.isRequired,
    adminUserListReady: PropTypes.bool.isRequired,
    fetchUsersIfNeeded: PropTypes.func.isRequired,
    intl: intlShape.isRequired,
    removeUserFromTeam: PropTypes.func.isRequired,
    userId: PropTypes.number.isRequired,
    users: PropTypes.array.isRequired,
    title: PropTypes.string.isRequired,
  };

  static defaultState = {
    email: '',
    name: '',
    type: 'user'
  };

  state = Object.assign({}, Admin.defaultState);

  componentWillMount() {
    this.props.fetchUsersIfNeeded();
  }

  handleChange = field => event => this.setState({ [field]: event.target.value });

  handleSubmit = (event) => {
    event.preventDefault();
    this.props.addUserToTeam(this.state);
    this.setState(Object.assign({}, Admin.defaultState));
  };

  handleDeleteClicked = id => () => {
    this.props.removeUserFromTeam(id);
  };

  render() {
    const { adminUserListReady, intl: { formatMessage: f }, userId, users } = this.props;
    const { email, name, type } = this.state;

    if (!adminUserListReady) {
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
                    {userId !== user.id && (
                      <button type="button" onClick={this.handleDeleteClicked(user.id)} aria-label="Remove">&times;</button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          <h2>Add User</h2>
          <form onSubmit={this.handleSubmit}>
            <label htmlFor="admin-name">
              Name:
            </label>
            <input
              id="admin-name"
              type="text"
              onChange={this.handleChange('name')}
              value={name}
            />
            <label htmlFor="admin-email">
              Email:
            </label>
            <input
              id="admin-email"
              type="email"
              onChange={this.handleChange('email')}
              value={email}
              required
            />
            <label htmlFor="admin-type">
              Type:
            </label>
            <select
              id="admin-type"
              onChange={this.handleChange('type')}
              value={type}
              required
            >
              <option value="user">{f(gm('userRole'))}</option>
              <option value="admin">{f(gm('adminRole'))}</option>
              <option value="owner">{f(gm('ownerRole'))}</option>
            </select>
            <input type="submit" />
          </form>
        </div>
      </div>
    );
  }
}

export default withStyles(s)(Admin);
