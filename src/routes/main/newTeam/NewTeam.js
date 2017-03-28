import React, { Component, PropTypes } from 'react';
import history from '../../../core/history';

export default class NewTeam extends Component {
  static propTypes = {
    createTeam: PropTypes.func.isRequired
  };

  state = {
    name: '',
    slug: ''
  };

  handleChange = field => event => this.setState({ [field]: event.target.value });

  handleSubmit = (event) => {
    event.preventDefault();

    this.props.createTeam(this.state).then(() => history.push('/teams'));
  }

  render() {
    const { name, slug } = this.state;

    return (
      <div className="page">
        <h2>Create a new team</h2>
        <form onSubmit={this.handleSubmit}>
          <label htmlFor="new-team-name">
            Name:
          </label>
          <input
            id="new-team-name"
            type="text"
            onChange={this.handleChange('name')}
            value={name}
            required
          />
          <label htmlFor="new-team-slug">
            URL:
          </label>
          https://lunch.labzero.com/<input
            id="new-team-slug"
            autoCorrect="off"
            autoCapitalize="off"
            type="text"
            value={slug}
            onChange={this.handleChange('slug')}
            required
          />
          <input type="submit" />
        </form>
      </div>
    );
  }
}
