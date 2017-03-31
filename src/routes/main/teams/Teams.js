import React, { Component, PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import Glyphicon from 'react-bootstrap/lib/Glyphicon';
import Grid from 'react-bootstrap/lib/Grid';
import Link from '../../../components/Link';
import s from './Teams.scss';

class Teams extends Component {
  static propTypes = {
    confirm: PropTypes.func.isRequired,
    host: PropTypes.string.isRequired,
    leaveTeam: PropTypes.func.isRequired,
    teams: PropTypes.array.isRequired
  };

  confirmLeave = team => () => {
    this.props.confirm({
      actionLabel: 'Leave',
      body: `Are you sure you want to leave this team?
You will need to be invited back by another member.`,
      handleSubmit: () => this.props.leaveTeam(team)
    });
  }

  render() {
    const { host, teams } = this.props;

    return (
      <Grid className={s.root}>
        <h2>Visit one of your teams:</h2>
        <ul className={`list-group ${s.list}`}>
          {teams.map(team => (
            <li className={`list-group-item ${s.item}`}>
              <a
                className={`list-group-item ${s.itemLink}`}
                key={team.id}
                href={`//${team.slug}.${host}`}
              >
                {team.name}
              </a>
              <button className={s.leave} onClick={this.confirmLeave(team)} aria-label="Leave">
                <Glyphicon glyph="remove" />
              </button>
            </li>
          ))}
        </ul>
        <div className={s.centerer}>
          <Link className="btn btn-default" to="/new-team">Create a new team</Link>
        </div>
      </Grid>
    );
  }
}

export default withStyles(s)(Teams);
