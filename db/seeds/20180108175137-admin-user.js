'use strict';
require('dotenv').config();
var bcrypt = require('bcrypt');
var name = process.env.SUPERUSER_NAME || 'superuser';

module.exports = {
  up: function (queryInterface, Sequelize) {
    var password = process.env.SUPERUSER_PASSWORD;
    var now = new Date().toISOString();

    function createUser(encrypted_password) {
      return queryInterface.bulkInsert('users', [{
        name: name,
        encrypted_password: encrypted_password,
        superuser: true,
        email: process.env.SUPERUSER_EMAIL,
        created_at: now,
        updated_at: now
      }], {});
    };

    return (password ? bcrypt.hash(password, 10).then(createUser) : createUser(null));
  },

  down: function (queryInterface, Sequelize) {
    return queryInterface.bulkDelete('users', {name: name}, {});
  }
};
