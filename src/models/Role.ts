import { InferAttributes, InferCreationAttributes, Model } from "sequelize";
import { RoleType } from "../interfaces";
import { sequelize, DataTypes } from "./db";

class Role extends Model<InferAttributes<Role>, InferCreationAttributes<Role>> {
  declare teamId: number;
  declare type: RoleType;
  declare userId: number;
}

Role.init(
  {
    type: {
      allowNull: false,
      type: DataTypes.ENUM("guest", "member", "owner"),
    },
    userId: {
      type: DataTypes.INTEGER,
      references: {
        model: "user",
        key: "id",
      },
      allowNull: false,
      onDelete: "cascade",
    },
    teamId: {
      type: DataTypes.INTEGER,
      references: {
        model: "team",
        key: "id",
      },
      allowNull: false,
      onDelete: "cascade",
    },
  },
  {
    indexes: [
      {
        fields: ["userId", "teamId"],
        unique: true,
      },
    ],
    modelName: "role",
    sequelize,
  }
);

export default Role;
