import { DataTypes } from "sequelize";

export const up = ({ context: queryInterface }) => {
  const Team = queryInterface.sequelize.define(
    "team",
    {
      name: DataTypes.STRING,
      slug: DataTypes.STRING(63),
      lat: DataTypes.DOUBLE,
      lng: DataTypes.DOUBLE,
      address: DataTypes.STRING,
    },
    {
      underscored: true,
    }
  );

  return Team.update(
    {
      address: "77 Battery Street, San Francisco, CA 94111, USA",
      lat: 37.79195,
      lng: -122.399991,
    },
    {
      where: { slug: "labzero" },
    }
  ).then(() =>
    Promise.all([
      queryInterface.changeColumn("teams", "lat", {
        type: DataTypes.DOUBLE,
        allowNull: false,
      }),
      queryInterface.changeColumn("teams", "lng", {
        type: DataTypes.DOUBLE,
        allowNull: false,
      }),
    ])
  );
};

export const down = ({ context: queryInterface }) =>
  Promise.all([
    queryInterface.changeColumn("teams", "lat", {
      allowNull: true,
      type: DataTypes.DOUBLE,
    }),
    queryInterface.changeColumn("teams", "lng", {
      allowNull: true,
      type: DataTypes.DOUBLE,
    }),
  ]);
