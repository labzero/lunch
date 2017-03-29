import React, { PropTypes } from 'react';
import Link from '../../../components/Link';

const Teams = ({ host, teams }) => (
  <div className="page">
    <h2>Visit one of your teams:</h2>
    <ul>
      {teams.map(team => (
        <li key={team.id}>
          <a href={`//${team.slug}.${host}`}>{team.name}</a>
        </li>
      ))}
    </ul>
    <Link to="/new-team">Create a new team</Link>
  </div>
);

Teams.propTypes = {
  host: PropTypes.string.isRequired,
  teams: PropTypes.array.isRequired
};

export default Teams;
