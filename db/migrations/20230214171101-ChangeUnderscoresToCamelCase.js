export const up = ({ context: queryInterface }) =>
  queryInterface.sequelize.transaction((transaction) =>
    Promise.all([
      queryInterface.renameTable("restaurants_tags", "restaurantsTags", {
        transaction,
      }),
    ]).then(() =>
      Promise.all([
        queryInterface.renameColumn(
          "decisions",
          "restaurant_id",
          "restaurantId",
          { transaction }
        ),
        queryInterface.renameColumn("decisions", "team_id", "teamId", {
          transaction,
        }),
        queryInterface.renameColumn("decisions", "created_at", "createdAt", {
          transaction,
        }),
        queryInterface.renameColumn("decisions", "updated_at", "updatedAt", {
          transaction,
        }),
        queryInterface.renameColumn(
          "invitations",
          "confirmed_at",
          "confirmedAt",
          { transaction },
          { transaction }
        ),
        queryInterface.renameColumn(
          "invitations",
          "confirmation_token",
          "confirmationToken",
          { transaction }
        ),
        queryInterface.renameColumn(
          "invitations",
          "confirmation_sent_at",
          "confirmationSentAt",
          { transaction }
        ),
        queryInterface.renameColumn("invitations", "created_at", "createdAt", {
          transaction,
        }),
        queryInterface.renameColumn("invitations", "updated_at", "updatedAt", {
          transaction,
        }),
        queryInterface.renameColumn("restaurants", "place_id", "placeId", {
          transaction,
        }),
        queryInterface.renameColumn("restaurants", "team_id", "teamId", {
          transaction,
        }),
        queryInterface.renameColumn("restaurants", "created_at", "createdAt", {
          transaction,
        }),
        queryInterface.renameColumn("restaurants", "updated_at", "updatedAt", {
          transaction,
        }),
        queryInterface.renameColumn(
          "restaurantsTags",
          "restaurant_id",
          "restaurantId",
          { transaction }
        ),
        queryInterface.renameColumn("restaurantsTags", "tag_id", "tagId", {
          transaction,
        }),
        queryInterface.renameColumn(
          "restaurantsTags",
          "created_at",
          "createdAt",
          { transaction }
        ),
        queryInterface.renameColumn(
          "restaurantsTags",
          "updated_at",
          "updatedAt",
          { transaction }
        ),
        queryInterface.renameColumn("roles", "user_id", "userId", {
          transaction,
        }),
        queryInterface.renameColumn("roles", "team_id", "teamId", {
          transaction,
        }),
        queryInterface.renameColumn("roles", "created_at", "createdAt", {
          transaction,
        }),
        queryInterface.renameColumn("roles", "updated_at", "updatedAt", {
          transaction,
        }),
        queryInterface.renameColumn("tags", "team_id", "teamId", {
          transaction,
        }),
        queryInterface.renameColumn("tags", "created_at", "createdAt", {
          transaction,
        }),
        queryInterface.renameColumn("tags", "updated_at", "updatedAt", {
          transaction,
        }),
        queryInterface.renameColumn("teams", "default_zoom", "defaultZoom", {
          transaction,
        }),
        queryInterface.renameColumn("teams", "sort_duration", "sortDuration", {
          transaction,
        }),
        queryInterface.renameColumn("teams", "created_at", "createdAt", {
          transaction,
        }),
        queryInterface.renameColumn("teams", "updated_at", "updatedAt", {
          transaction,
        }),
        queryInterface.renameColumn("users", "google_id", "googleId", {
          transaction,
        }),
        queryInterface.renameColumn(
          "users",
          "encrypted_password",
          "encryptedPassword",
          { transaction }
        ),
        queryInterface.renameColumn(
          "users",
          "reset_password_token",
          "resetPasswordToken",
          { transaction }
        ),
        queryInterface.renameColumn(
          "users",
          "reset_password_sent_at",
          "resetPasswordSentAt",
          { transaction }
        ),
        queryInterface.renameColumn(
          "users",
          "confirmation_token",
          "confirmationToken",
          { transaction }
        ),
        queryInterface.renameColumn(
          "users",
          "confirmation_sent_at",
          "confirmationSentAt",
          { transaction }
        ),
        queryInterface.renameColumn("users", "confirmed_at", "confirmedAt", {
          transaction,
        }),
        queryInterface.renameColumn("users", "name_changed", "nameChanged", {
          transaction,
        }),
        queryInterface.renameColumn("users", "created_at", "createdAt", {
          transaction,
        }),
        queryInterface.renameColumn("users", "updated_at", "updatedAt", {
          transaction,
        }),
        queryInterface.renameColumn("votes", "user_id", "userId", {
          transaction,
        }),
        queryInterface.renameColumn("votes", "restaurant_id", "restaurantId", {
          transaction,
        }),
        queryInterface.renameColumn("votes", "created_at", "createdAt", {
          transaction,
        }),
        queryInterface.renameColumn("votes", "updated_at", "updatedAt", {
          transaction,
        }),
      ])
    )
  );

export const down = ({ context: queryInterface }) =>
  queryInterface.sequelize.transaction((transaction) =>
    Promise.all([
      queryInterface.renameTable("restaurantsTags", "restaurants_tags", {
        transaction,
      }),
    ]).then(() =>
      Promise.all([
        queryInterface.renameColumn(
          "decisions",
          "restaurantId",
          "restaurant_id",
          { transaction }
        ),
        queryInterface.renameColumn("decisions", "teamId", "team_id", {
          transaction,
        }),
        queryInterface.renameColumn("decisions", "createdAt", "created_at", {
          transaction,
        }),
        queryInterface.renameColumn("decisions", "updatedAt", "updated_at", {
          transaction,
        }),
        queryInterface.renameColumn(
          "invitations",
          "confirmedAt",
          "confirmed_at",
          { transaction }
        ),
        queryInterface.renameColumn(
          "invitations",
          "confirmationToken",
          "confirmation_token",
          { transaction }
        ),
        queryInterface.renameColumn(
          "invitations",
          "confirmationSentAt",
          "confirmation_sent_at",
          { transaction }
        ),
        queryInterface.renameColumn("invitations", "createdAt", "created_at", {
          transaction,
        }),
        queryInterface.renameColumn("invitations", "updatedAt", "updated_at", {
          transaction,
        }),
        queryInterface.renameColumn("restaurants", "placeId", "place_id", {
          transaction,
        }),
        queryInterface.renameColumn("restaurants", "teamId", "team_id", {
          transaction,
        }),
        queryInterface.renameColumn("restaurants", "createdAt", "created_at", {
          transaction,
        }),
        queryInterface.renameColumn("restaurants", "updatedAt", "updated_at", {
          transaction,
        }),
        queryInterface.renameColumn(
          "restaurants_tags",
          "restaurantId",
          "restaurant_id",
          { transaction }
        ),
        queryInterface.renameColumn("restaurants_tags", "tagId", "tag_id", {
          transaction,
        }),
        queryInterface.renameColumn(
          "restaurants_tags",
          "createdAt",
          "created_at",
          { transaction }
        ),
        queryInterface.renameColumn(
          "restaurants_tags",
          "updatedAt",
          "updated_at",
          { transaction }
        ),
        queryInterface.renameColumn("roles", "userId", "user_id", {
          transaction,
        }),
        queryInterface.renameColumn("roles", "teamId", "team_id", {
          transaction,
        }),
        queryInterface.renameColumn("roles", "createdAt", "created_at", {
          transaction,
        }),
        queryInterface.renameColumn("roles", "updatedAt", "updated_at", {
          transaction,
        }),
        queryInterface.renameColumn("tags", "teamId", "team_id", {
          transaction,
        }),
        queryInterface.renameColumn("tags", "createdAt", "created_at", {
          transaction,
        }),
        queryInterface.renameColumn("tags", "updatedAt", "updated_at", {
          transaction,
        }),
        queryInterface.renameColumn("teams", "defaultZoom", "default_zoom", {
          transaction,
        }),
        queryInterface.renameColumn("teams", "sortDuration", "sort_duration", {
          transaction,
        }),
        queryInterface.renameColumn("teams", "createdAt", "created_at", {
          transaction,
        }),
        queryInterface.renameColumn("teams", "updatedAt", "updated_at", {
          transaction,
        }),
        queryInterface.renameColumn("users", "googleId", "google_id", {
          transaction,
        }),
        queryInterface.renameColumn(
          "users",
          "encryptedPassword",
          "encrypted_password",
          { transaction }
        ),
        queryInterface.renameColumn(
          "users",
          "resetPasswordToken",
          "reset_password_token",
          { transaction }
        ),
        queryInterface.renameColumn(
          "users",
          "resetPasswordSentAt",
          "reset_password_sent_at",
          { transaction }
        ),
        queryInterface.renameColumn(
          "users",
          "confirmationToken",
          "confirmation_token",
          { transaction }
        ),
        queryInterface.renameColumn(
          "users",
          "confirmationSentAt",
          "confirmation_sent_at",
          { transaction }
        ),
        queryInterface.renameColumn("users", "confirmedAt", "confirmed_at", {
          transaction,
        }),
        queryInterface.renameColumn("users", "nameChanged", "name_changed", {
          transaction,
        }),
        queryInterface.renameColumn("users", "createdAt", "created_at", {
          transaction,
        }),
        queryInterface.renameColumn("users", "updatedAt", "updated_at", {
          transaction,
        }),
        queryInterface.renameColumn("votes", "userId", "user_id", {
          transaction,
        }),
        queryInterface.renameColumn("votes", "restaurantId", "restaurant_id", {
          transaction,
        }),
        queryInterface.renameColumn("votes", "createdAt", "created_at", {
          transaction,
        }),
        queryInterface.renameColumn("votes", "updatedAt", "updated_at", {
          transaction,
        }),
      ])
    )
  );
