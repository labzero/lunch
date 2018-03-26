import { host, wsPort } from './config';

const getInitialState = () => ({
  restaurants: {
    didInvalidate: true,
    nameFilter: '',
    isFetching: false,
    items: []
  },
  decisions: {
    isFetching: false,
    didInvalidate: true,
    items: [],
  },
  flashes: [],
  host,
  notifications: [],
  modals: {},
  listUi: {
    flipMove: true,
  },
  locale: 'en',
  mapUi: {
    infoWindow: {},
    showUnvoted: true,
    showPOIs: false
  },
  pageUi: {},
  tagFilters: [],
  tagExclusions: [],
  tags: {
    isFetching: false,
    didInvalidate: true,
    items: []
  },
  team: {},
  teams: {
    isFetching: false,
    didInvalidate: true,
    items: []
  },
  user: {},
  users: {
    isFetching: false,
    didInvalidate: true,
    items: []
  },
  wsPort: module.hot ? wsPort : 0
});

export default (stateData) => {
  const initialState = getInitialState();
  if (stateData.teams) {
    initialState.teams.items = stateData.teams.map(t => t.toJSON());
    initialState.teams.didInvalidate = false;
  }
  if (stateData.user) {
    initialState.user = stateData.user;
  }
  if (stateData.team) {
    initialState.team = stateData.team;
  }
  if (stateData.host) {
    initialState.host = stateData.host;
  }
  if (stateData.flashes) {
    initialState.flashes = stateData.flashes;
  }
  return initialState;
};
