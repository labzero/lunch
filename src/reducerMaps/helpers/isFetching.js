import update from 'react-addons-update';

export default state =>
  update(state, {
    $merge: {
      isFetching: true
    }
  });
