require('dotenv').config();
const bcrypt = require('bcrypt');

const name = process.env.SUPERUSER_NAME || 'superuser';

module.exports = {
  up(queryInterface) {
    const password = process.env.SUPERUSER_PASSWORD;
    const now = new Date().toISOString();

    function createUser(encryptedPassword) {
      return queryInterface.bulkInsert('users', [{
        name,
        encrypted_password: encryptedPassword,
        superuser: true,
        email: process.env.SUPERUSER_EMAIL,
        created_at: now,
        updated_at: now
      }], {});
    }

    return (password ? bcrypt.hash(password, 10).then(createUser) : createUser(null));
  },

  down(queryInterface) {
    return queryInterface.bulkDelete('users', { name }, {});
  }
};
