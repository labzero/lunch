export default (obj?: Record<string, any>) => {
  const esModule = obj || {};
  Object.defineProperty(esModule, "__esModule", {
    value: true,
  });
  return esModule;
};
