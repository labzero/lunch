import React, { Component, PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import Link from '../Link';
import s from './Menu.scss';

class Menu extends Component {
  static propTypes = {
    closeMenu: PropTypes.func.isRequired,
    hasGuestRole: PropTypes.bool.isRequired,
    hasMemberRole: PropTypes.bool.isRequired,
    open: PropTypes.bool.isRequired,
    teamSlug: PropTypes.string,
    user: PropTypes.object.isRequired
  }

  static defaultProps = {
    teamSlug: undefined
  };

  render() {
    const { closeMenu, hasGuestRole, hasMemberRole, open, teamSlug, user } = this.props;

    return (
      <nav className={`${s.root} ${open ? s.open : ''}`}>
        <div className={s.name}>
          {user.name}
        </div>
        <div className={s.lists}>
          {teamSlug && (
            <ul className={s.list}>
              {hasMemberRole && (
                <li className={s.item}>
                  <Link className={s.button} onClick={closeMenu} to={`/teams/${teamSlug}/team`}>Team</Link>
                </li>
              )}
              {hasGuestRole && (
                <li className={s.item}>
                  <Link className={s.button} onClick={closeMenu} to={`/teams/${teamSlug}/tags`}>Tags</Link>
                </li>
              )}
            </ul>
          )}
          <ul className={s.list}>
            <li className={s.item}>
              <Link className={s.button} onClick={closeMenu} to="/teams">My Teams</Link>
            </li>
            <li className={`${s.item} ${s.logout}`}>
              <a className={s.button} onClick={closeMenu} href="/logout">Log Out</a>
            </li>
          </ul>
        </div>
      </nav>
    );
  }
}

export default withStyles(s)(Menu);
