import React, { PropTypes } from 'react';
import Link from '../../components/Link';

const Teams = ({ teams }) => (
  <div className="page">
    <h2>Visit one of your teams:</h2>
    <ul>
      {teams.map(team => (
        <li key={team.id}>
          <Link to={`/teams/${team.slug}`}>{team.name}</Link>
        </li>
      ))}
    </ul>
    <h2>Or join an existing one:</h2>
    <form>
      <input type="text" />
    </form>
    <Link to="/new-team">Create a new team</Link>
  </div>
);

Teams.propTypes = {
  teams: PropTypes.array.isRequired
};

export default Teams;
