import React, { PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import Grid from 'react-bootstrap/lib/Grid';
import Link from '../../../components/Link';
import s from './Teams.scss';

const Teams = ({ host, teams }) => (
  <Grid className={s.root}>
    <h2>Visit one of your teams:</h2>
    <div className={`list-group ${s.list}`}>
      {teams.map(team => (
        <a
          className="list-group-item"
          key={team.id}
          href={`//${team.slug}.${host}`}
        >
          {team.name}
        </a>
      ))}
    </div>
    <div className={s.centerer}>
      <Link className="btn btn-default" to="/new-team">Create a new team</Link>
    </div>
  </Grid>
);

Teams.propTypes = {
  host: PropTypes.string.isRequired,
  teams: PropTypes.array.isRequired
};

export default withStyles(s)(Teams);
