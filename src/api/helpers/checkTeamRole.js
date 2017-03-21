import { Team } from '../../models';
import hasRole from '../../helpers/hasRole';

export default role => async (req, res, next) => {
  const team = await Team.findOne({ where: { slug: req.params.slug } });

  if (team && hasRole(req.user, team, role)) {
    req.team = team; // eslint-disable-line no-param-reassign
    next();
  } else {
    res.status(404).json({ error: true, data: { message: 'Not found' } });
  }
};
