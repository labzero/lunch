import { schema } from "normalizr";

export const decision = new schema.Entity("decisions");
export const vote = new schema.Entity("votes");
export const restaurant = new schema.Entity("restaurants", {
  votes: [vote],
});
export const tag = new schema.Entity("tags");
export const team = new schema.Entity("teams");
export const user = new schema.Entity("users");
