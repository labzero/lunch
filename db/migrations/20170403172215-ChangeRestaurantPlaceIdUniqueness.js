import { DataTypes } from "sequelize";

exports.up = ({ context: queryInterface }) =>
  queryInterface
    .changeColumn("restaurants", "place_id", {
      type: DataTypes.STRING,
      unique: false,
    })
    .then(() =>
      queryInterface.sequelize.query(
        "ALTER TABLE restaurants DROP CONSTRAINT restaurants_place_id_key;"
      )
    );

exports.down = ({ context: queryInterface }) =>
  queryInterface.changeColumn("restaurants", "place_id", {
    type: DataTypes.STRING,
    unique: true,
  });
