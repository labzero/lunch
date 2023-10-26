import { DataTypes } from "sequelize";

export const up = ({ context: queryInterface }) =>
  queryInterface.sequelize
    .query(
      "ALTER TABLE decisions DROP CONSTRAINT IF EXISTS decisions_restaurant_id_fkey"
    )
    .then(() =>
      queryInterface.sequelize
        .query(
          "ALTER TABLE decisions DROP CONSTRAINT IF EXISTS restaurant_id_foreign_idx"
        )
        .then(() =>
          queryInterface.changeColumn("decisions", "restaurant_id", {
            type: DataTypes.INTEGER,
            references: {
              model: "restaurants",
              key: "id",
            },
            allowNull: false,
            onDelete: "cascade",
          })
        )
    );

export const down = ({ context: queryInterface }) =>
  queryInterface.sequelize
    .query(
      "ALTER TABLE decisions DROP CONSTRAINT IF EXISTS restaurant_id_foreign_idx"
    )
    .then(() =>
      queryInterface.changeColumn("decisions", "restaurant_id", {
        type: DataTypes.INTEGER,
        references: {
          model: "restaurants",
          key: "id",
        },
        allowNull: false,
      })
    );
