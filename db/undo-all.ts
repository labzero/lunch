import createUmzug from "./createUmzug";

(async () => {
  await createUmzug("./seeds/*.js").down({ to: 0 });
  await createUmzug().down({ to: 0 });
})();
