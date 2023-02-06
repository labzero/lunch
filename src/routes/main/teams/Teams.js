import PropTypes from 'prop-types';
import React, { Component } from 'react';
import withStyles from 'isomorphic-style-loader/withStyles';
import Glyphicon from 'react-bootstrap/lib/Glyphicon';
import Grid from 'react-bootstrap/lib/Grid';
import Link from '../../../components/Link';
import s from './Teams.scss';

class Teams extends Component {
  static propTypes = {
    confirm: PropTypes.func.isRequired,
    host: PropTypes.string.isRequired,
    leaveTeam: PropTypes.func.isRequired,
    teams: PropTypes.array.isRequired,
  };

  confirmLeave = (team) => () => {
    this.props.confirm({
      actionLabel: 'Leave',
      body: `Are you sure you want to leave this team?
You will need to be invited back by another member.`,
      handleSubmit: () => this.props.leaveTeam(team),
    });
  };

  render() {
    const { host, teams } = this.props;

    return (
      <div className={s.root}>
        <Grid>
          {teams.length ? (
            <div>
              <h2>Visit one of your teams:</h2>
              <ul className={`list-group ${s.list}`}>
                {teams.map((team) => (
                  <li className={`list-group-item ${s.item}`} key={team.slug}>
                    <a
                      className={`list-group-item ${s.itemLink}`}
                      key={team.id}
                      href={`//${team.slug}.${host}`}
                    >
                      {team.name}
                    </a>
                    <button
                      className={s.leave}
                      onClick={this.confirmLeave(team)}
                      aria-label="Leave"
                      type="button"
                    >
                      <Glyphicon glyph="remove" />
                    </button>
                  </li>
                ))}
              </ul>
            </div>
          ) : (
            <div className={s.centerer}>
              <h2>You&rsquo;re not currently a part of any teams!</h2>
            </div>
          )}
          <div className={s.centerer}>
            <Link className="btn btn-default" to="/new-team">
              Create a new team
            </Link>
          </div>
        </Grid>
      </div>
    );
  }
}

export default withStyles(s)(Teams);
