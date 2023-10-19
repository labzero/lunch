import { DataTypes } from "sequelize";

exports.up = ({ context: queryInterface }) => {
  const User = queryInterface.sequelize.define(
    "user",
    {
      google_id: DataTypes.STRING,
      name: DataTypes.STRING,
      email: DataTypes.STRING,
    },
    {
      underscored: true,
    }
  );

  const Team = queryInterface.sequelize.define(
    "team",
    {
      name: DataTypes.STRING,
    },
    {
      underscored: true,
    }
  );

  return queryInterface
    .createTable(
      "roles",
      {
        id: {
          allowNull: false,
          autoIncrement: true,
          primaryKey: true,
          type: DataTypes.INTEGER,
        },
        type: {
          allowNull: false,
          type: DataTypes.ENUM("guest", "member", "owner"),
        },
        team_id: {
          type: DataTypes.INTEGER,
          references: {
            model: "teams",
            key: "id",
          },
          allowNull: false,
          onDelete: "cascade",
        },
        user_id: {
          type: DataTypes.INTEGER,
          references: {
            model: "users",
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
            fields: ["team_id", "user_id"],
          },
        },
      }
    )
    .then(() => User.findAll())
    .then((users) =>
      Team.findOne({ where: { name: "Lab Zero" } }).then((team) => {
        const Role = queryInterface.sequelize.define(
          "role",
          {
            type: {
              allowNull: false,
              type: DataTypes.ENUM("guest", "member", "owner"),
            },
            user_id: {
              type: DataTypes.INTEGER,
              references: {
                model: "user",
                key: "id",
              },
              allowNull: false,
              onDelete: "cascade",
            },
            team_id: {
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
            uniqueKeys: {
              unique: {
                fields: ["user_id", "team_id"],
              },
            },
            underscored: true,
          }
        );

        return Promise.all(
          users.map((user) =>
            Role.create({
              team_id: team.id,
              user_id: user.id,
              type: user.email.match(/@labzero\.com$/) ? "member" : "guest",
            })
          )
        );
      })
    );
};

exports.down = ({ context: queryInterface }) =>
  queryInterface
    .dropTable("roles", {})
    .then(() => queryInterface.sequelize.query("DROP TYPE enum_roles_type"));
