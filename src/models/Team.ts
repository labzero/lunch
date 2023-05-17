import { DoubleDataType, Model } from "sequelize";
import { sequelize, DataTypes } from "./db";
import User from "./User";

class Team extends Model {
  static findAllForUser = (user: User) =>
    Team.findAll({
      order: [["createdAt", "ASC"]],
      where: { id: user.roles.map((r) => r.teamId) },
      attributes: {
        exclude: ["createdAt", "updatedAt"],
      },
    });

  declare id: number;
  declare name: string;
  declare slug: string;
  declare defaultZoom: number;
  declare sortDuration: number;
  declare lat: DoubleDataType;
  declare lng: DoubleDataType;
  declare address: string;
}

Team.init(
  {
    name: DataTypes.STRING,
    slug: {
      allowNull: false,
      type: DataTypes.STRING(63),
    },
    defaultZoom: DataTypes.INTEGER,
    sortDuration: DataTypes.INTEGER,
    lat: {
      allowNull: false,
      type: DataTypes.DOUBLE,
    },
    lng: {
      allowNull: false,
      type: DataTypes.DOUBLE,
    },
    address: DataTypes.STRING,
  },
  {
    indexes: [
      {
        fields: ["createdAt"],
      },
    ],
    modelName: "team",
    sequelize,
  }
);

export default Team;
