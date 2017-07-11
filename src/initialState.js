import { host, wsPort } from './config';

const getInitialState = () => ({
  restaurants: {
    isFetching: false,
    didInvalidate: true,
    items: []
  },
  decision: {
    isFetching: false,
    didInvalidate: true,
    inst: null
  },
  flashes: [],
  host,
  notifications: [],
  modals: {},
  listUi: {},
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
  tagUi: {
    filterForm: {},
    exclusionForm: {}
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
  wsPort: process.env.BS_RUNNING ? wsPort : 0
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
