import hasRole from '../../helpers/hasRole';

export default role => (req, res, next) => {
  if (hasRole(req.user, req.team, role)) {
    next();
  } else {
    res.status(404).json({ error: true, data: { message: 'Not found' } });
  }
};
