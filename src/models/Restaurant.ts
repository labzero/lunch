import {
  BelongsToMany,
  Column,
  HasMany,
  Model,
  Table,
} from "sequelize-typescript";
import { sequelize } from "../db";
import Decision from "./Decision";
import RestaurantTag from "./RestaurantTag";
import Tag from "./Tag";
import Team from "./Team";
import Vote from "./Vote";

@Table({ modelName: "restaurant" })
class Restaurant extends Model {
  static findAllWithTagIds = ({ teamId }: { teamId: number }) =>
    Team.findByPk(teamId).then((team) =>
      team
        ? Restaurant.findAll({
            attributes: {
              include: [
                [
                  sequelize.literal(`ARRAY(SELECT "tagId" from "restaurantsTags"
                where "restaurantsTags"."restaurantId" = "restaurant"."id")`),
                  "tags",
                ],
                [
                  sequelize.literal(`(SELECT COUNT(*) from "votes" as "allVotes"
                where "allVotes"."restaurantId" = "restaurant"."id"
                and "allVotes"."createdAt" >= CURRENT_DATE - INTERVAL '${team.sortDuration} days')`),
                  "all_vote_count",
                ],
                [
                  sequelize.literal(`(SELECT COUNT(*) from "decisions" as "allDecisions"
                where "allDecisions"."restaurantId" = "restaurant"."id"
                and "allDecisions"."createdAt" >= CURRENT_DATE - INTERVAL '${team.sortDuration} days')`),
                  "all_decision_count",
                ],
              ],
              exclude: ["updatedAt"],
            },
            include: [
              {
                model: Vote.scope("fromToday"),
                required: false,
                attributes: ["id", "userId", "restaurantId", "createdAt"],
              },
              {
                model: Decision.scope("fromToday"),
                required: false,
                attributes: ["id"],
              },
            ],
            order: [
              [Restaurant.associations.decisions, "id", "NULLS LAST"], // decision of the day
              sequelize.literal(
                '(COUNT(*) OVER(PARTITION BY "restaurant"."id")) DESC'
              ), // number of votes
              sequelize.literal(
                '(SELECT CASE WHEN "votes"."id" IS NULL THEN 1 ELSE 0 END)'
              ), // votes vs. no votes
              sequelize.literal("all_decision_count ASC"), // past decisions on bottom
              sequelize.literal("all_vote_count DESC"), // past votes on top
              ["name", "ASC"], // alphabetical
            ],
            where: {
              // eslint-disable-next-line camelcase
              teamId,
            },
          })
        : []
    );

  @Column
  name: string;

  @Column
  address: string;

  @Column
  lat: number;

  @Column
  lng: number;

  @Column
  placeId: string;

  @Column
  teamId: string;

  @HasMany(() => Vote)
  votes: Vote[];

  @HasMany(() => Decision)
  decisions: Decision[];

  @BelongsToMany(() => Tag, () => RestaurantTag)
  tags: Tag[];
}

export default Restaurant;
