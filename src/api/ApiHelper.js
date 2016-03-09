export function loggedIn(req, res, next) {
  if (req.user) {
    next();
  } else {
    res.redirect('/login');
  }
}

export function errorCatcher(res, err) {
  res.status(500).json({ error: true, data: { message: err.message } });
}
