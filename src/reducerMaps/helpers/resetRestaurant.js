import update from 'react-addons-update';

export default (state, action) =>
  update(state, {
    $merge: {
      [action.id]: {
        $set: {}
      }
    }
  });
