import { sequelize, DataTypes } from "./db";

const RestaurantTag = sequelize.define(
  "restaurantsTags",
  {
    restaurantId: {
      type: DataTypes.INTEGER,
      references: {
        model: "restaurant",
        key: "id",
      },
      allowNull: false,
      onDelete: "cascade",
    },
    tagId: {
      type: DataTypes.INTEGER,
      references: {
        model: "tag",
        key: "id",
      },
      allowNull: false,
      onDelete: "cascade",
    },
  },
  {
    indexes: [
      {
        fields: ["restaurantId", "tagId"],
        unique: true,
      },
    ],
  }
);
RestaurantTag.removeAttribute("id");

export default RestaurantTag;
