export default (obj) => {
  const esModule = obj || {};
  Object.defineProperty(esModule, '__esModule', {
    value: true,
  });
  return esModule;
};
