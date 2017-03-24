export default (res, err) => {
  res.status(500).json({ error: true, data: { message: err.message } });
};
