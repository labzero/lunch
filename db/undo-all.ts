import createUmzug from "./createUmzug";

(async () => {
  await createUmzug().down({ to: 0 });
})();
