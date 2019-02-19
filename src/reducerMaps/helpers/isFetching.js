import update from 'immutability-helper';

export default state => update(state, {
  $merge: {
    isFetching: true
  }
});
