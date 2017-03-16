export default (res, err) => {
  // eslint-disable-next-line no-console
  console.error(err);
  res.status(500).json({ error: true, data: { message: err.message } });
};
