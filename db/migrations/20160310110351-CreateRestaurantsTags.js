import { DataTypes } from "sequelize";

exports.up = ({ context: queryInterface }) =>
  queryInterface.createTable(
    "restaurants_tags",
    {
      restaurant_id: {
        type: DataTypes.INTEGER,
        references: {
          model: "restaurants",
          key: "id",
        },
        allowNull: false,
        onDelete: "cascade",
      },
      tag_id: {
        type: DataTypes.INTEGER,
        references: {
          model: "tags",
          key: "id",
        },
        allowNull: false,
        onDelete: "cascade",
      },
      created_at: {
        allowNull: false,
        type: DataTypes.DATE,
      },
      updated_at: {
        allowNull: false,
        type: DataTypes.DATE,
      },
    },
    {
      uniqueKeys: {
        unique: {
          fields: ["restaurant_id", "tag_id"],
        },
      },
    }
  );

exports.down = ({ context: queryInterface }) =>
  queryInterface.dropTable("restaurants_tags");
