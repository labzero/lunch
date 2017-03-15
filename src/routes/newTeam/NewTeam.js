import React, { Component, PropTypes } from 'react';

export default class NewTeam extends Component {
  static propTypes = {
    createNewTeam: PropTypes.func.isRequired
  };

  state = {
    name: ''
  };

  handleChange = event => this.setState({ name: event.target.value });

  handleSubmit = (event) => {
    event.preventDefault();

    this.props.createNewTeam(this.state.name);
  }

  render() {
    const { name } = this.state;

    return (
      <div className="page">
        <h2>Create a new team</h2>
        <form onSubmit={this.handleSubmit}>
          <input type="text" value={name} onChange={this.handleChange} />
        </form>
      </div>
    );
  }
}
