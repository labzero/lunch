import update from "immutability-helper";

export default (target, key, obj) => {
  if (target[key] === undefined) {
    return update(target, {
      [key]: {
        $set: obj,
      },
    });
  }
  return update(target, {
    [key]: {
      $merge: obj,
    },
  });
};
