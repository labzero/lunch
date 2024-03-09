import React from "react";
import withStyles from "isomorphic-style-loader/withStyles";
import Container from "react-bootstrap/Container";
import { AppContext, TeamWithAdminData } from "src/interfaces";
import { Table } from "react-bootstrap";
import dayjs from "dayjs";
import s from "./Admin.scss";

interface AdminProps {
  host: string;
}

const formatString = "MMMM D, YYYY h:mm A";

const Admin = ({ host }: AdminProps, { payload }: AppContext) => {
  const teams: TeamWithAdminData[] = payload?.["/api/teams/all"].data;

  return (
    <div className={s.root}>
      <Container>
        <h2>Teams</h2>
        <Table responsive>
          <thead>
            <tr>
              <th>Name</th>
              <th>Members</th>
              <th>Created at</th>
              <th>Last voted at</th>
            </tr>
          </thead>
          <tbody>
            {teams.map((team) => (
              <tr key={team.id}>
                <td>
                  <a href={`//${team.slug}.${host}`}>{team.name}</a>
                </td>
                <td>{team.roleCount}</td>
                <td>{dayjs(team.createdAt).format(formatString)}</td>
                <td>
                  {team.recentVoteCreatedAt != null &&
                    dayjs(team.recentVoteCreatedAt).format(formatString)}
                </td>
              </tr>
            ))}
          </tbody>
        </Table>
      </Container>
    </div>
  );
};

export default withStyles(s)(Admin);
