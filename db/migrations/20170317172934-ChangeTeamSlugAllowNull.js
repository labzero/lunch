import { DataTypes } from "sequelize";

export const up = ({ context: queryInterface }) => {
  const Team = queryInterface.sequelize.define(
    "team",
    {
      name: DataTypes.STRING,
      slug: DataTypes.STRING(63),
    },
    {
      underscored: true,
    }
  );

  return Team.update({ slug: "labzero" }, { where: { name: "Lab Zero" } }).then(
    () =>
      queryInterface.changeColumn("teams", "slug", {
        allowNull: false,
        type: DataTypes.STRING(63),
      })
  );
};

export const down = ({ context: queryInterface }) =>
  queryInterface.changeColumn("teams", "slug", {
    allowNull: true,
    type: DataTypes.STRING(63),
  });
