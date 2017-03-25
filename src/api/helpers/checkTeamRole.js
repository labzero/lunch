import getTeamIfHasRole from './getTeamIfHasRole';

export default role => async (req, res, next) => {
  const team = await getTeamIfHasRole(req.user, req.params.slug, role);

  if (team) {
    req.team = team; // eslint-disable-line no-param-reassign
    next();
  } else {
    res.status(404).json({ error: true, data: { message: 'Not found' } });
  }
};
