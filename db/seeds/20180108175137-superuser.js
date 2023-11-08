/* eslint-disable @typescript-eslint/no-var-requires */
const name = process.env.SUPERUSER_NAME || "superuser";

module.exports = {
  up({ context: queryInterface }) {
    const password = process.env.SUPERUSER_PASSWORD;
    const now = new Date().toISOString();

    function createUser(encryptedPassword) {
      return queryInterface.bulkInsert(
        "users",
        [
          {
            name,
            encryptedPassword,
            superuser: true,
            email: process.env.SUPERUSER_EMAIL,
            createdAt: now,
            updatedAt: now,
          },
        ],
        {}
      );
    }

    return password
      ? Bun.password
          .hash(password, { algorithm: "bcrypt", cost: 10 })
          .then(createUser)
      : createUser(null);
  },

  down({ context: queryInterface }) {
    return queryInterface.bulkDelete("users", { name }, {});
  },
};
