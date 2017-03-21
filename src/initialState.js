import { port } from './config';

const getInitialState = () => ({
  restaurants: {
    isFetching: false,
    didInvalidate: true,
    items: [],
    teamSlug: null
  },
  decision: {
    isFetching: false,
    didInvalidate: true,
    inst: null,
    teamSlug: null
  },
  flashes: [],
  notifications: [],
  modals: {},
  user: {},
  users: {
    isFetching: false,
    didInvalidate: true,
    items: [],
    teamSlug: null
  },
  latLng: {
    lat: parseFloat(process.env.SUGGEST_LAT),
    lng: parseFloat(process.env.SUGGEST_LNG)
  },
  listUi: {},
  mapUi: {
    showUnvoted: true
  },
  tagFilters: [],
  tagExclusions: [],
  tags: {
    isFetching: false,
    didInvalidate: true,
    items: [],
    teamSlug: null
  },
  tagUi: {
    filterForm: {},
    exclusionForm: {}
  },
  teams: {
    isFetching: false,
    didInvalidate: true,
    items: []
  },
  pageUi: {},
  wsPort: process.env.BS_RUNNING ? port : 0
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
  return initialState;
};
