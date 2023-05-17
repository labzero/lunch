import update from "immutability-helper";

export default (state, action) =>
  update(state, {
    $merge: {
      [action.id]: {
        $set: {},
      },
    },
  });
