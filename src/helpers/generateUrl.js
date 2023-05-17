export default (req, host, path = "") => `${req.protocol}://${host}${path}`;
