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
  latLng: {
    lat: parseFloat(process.env.SUGGEST_LAT),
    lng: parseFloat(process.env.SUGGEST_LNG)
  },
  listUi: {},
  locale: 'en',
  mapUi: {
    showUnvoted: true
  },
  pageUi: {},
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
  user: {},
  users: {
    isFetching: false,
    didInvalidate: true,
    items: [],
    teamSlug: null
  },
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
