import { DataTypes } from "sequelize";

export const up = ({ context: queryInterface }) =>
  queryInterface
    .changeColumn("tags", "name", {
      type: DataTypes.STRING,
      allowNull: false,
      unique: false,
    })
    .then(() =>
      queryInterface.sequelize.query(
        "ALTER TABLE tags DROP CONSTRAINT IF EXISTS tags_name_key;"
      )
    );

export const down = ({ context: queryInterface }) =>
  queryInterface.changeColumn("tags", "name", {
    type: DataTypes.STRING,
    unique: true,
  });
