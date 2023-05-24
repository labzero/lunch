import React, { Component } from "react";
import withStyles from "isomorphic-style-loader/withStyles";
import { Team, User } from "../../interfaces";
import Link from "../Link/Link";
import s from "./Menu.scss";

export interface MenuProps {
  closeMenu: () => void;
  hasGuestRole: boolean;
  hasMemberRole: boolean;
  host: string;
  open: boolean;
  team?: Team;
  user: User;
}

class Menu extends Component<MenuProps> {
  static defaultProps = {
    team: undefined,
  };

  render() {
    const { closeMenu, hasGuestRole, hasMemberRole, host, open, team, user } =
      this.props;

    const tabIndex = open ? 0 : -1;

    return (
      <nav className={`${s.root} ${open ? s.open : ""}`}>
        <div className={s.name}>
          <div>{user.name}</div>
          <div>{user.email}</div>
        </div>
        <div className={s.lists}>
          {team && (
            <ul className={s.list}>
              {hasMemberRole && (
                <li className={s.item}>
                  <Link
                    className={s.button}
                    onClick={closeMenu}
                    tabIndex={tabIndex}
                    to="/team"
                  >
                    Team
                  </Link>
                </li>
              )}
              {hasGuestRole && (
                <li className={s.item}>
                  <Link
                    className={s.button}
                    onClick={closeMenu}
                    tabIndex={tabIndex}
                    to="/tags"
                  >
                    Tags
                  </Link>
                </li>
              )}
            </ul>
          )}
          <ul className={s.list}>
            <li className={s.item}>
              <a
                className={s.button}
                onClick={closeMenu}
                tabIndex={tabIndex}
                href={`//${host}/teams`}
              >
                My Teams
              </a>
            </li>
            <li className={s.item}>
              <a
                className={s.button}
                onClick={closeMenu}
                tabIndex={tabIndex}
                href={`//${host}/account`}
              >
                Account
              </a>
            </li>
            <li className={`${s.item} ${s.logout}`}>
              <a
                className={s.button}
                onClick={closeMenu}
                tabIndex={tabIndex}
                href={`//${host}/logout`}
              >
                Log Out
              </a>
            </li>
          </ul>
        </div>
      </nav>
    );
  }
}

export default withStyles(s)(Menu);
