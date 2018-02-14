export default (req, res, next) => {
  if (req.user) {
    next();
  } else if (req.accepts('html') === 'html') {
    res.redirect('/login');
  } else {
    res.status(401).send();
  }
};
