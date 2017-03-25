import { Team } from '../../models';
import hasRole from '../../helpers/hasRole';

export default async (user, teamSlug, role) => {
  const team = await Team.findOne({ where: { slug: teamSlug } });

  return team && hasRole(user, team, role) ? team : undefined;
};
