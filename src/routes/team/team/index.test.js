/* eslint-env mocha */
/* eslint-disable no-unused-expressions, no-underscore-dangle, import/no-duplicates */

import { expect } from 'chai';
import proxyquire from 'proxyquire';
import configureStore from 'redux-mock-store';
import mockEsmodule from '../../../../test/mockEsmodule';

const proxyquireStrict = proxyquire.noCallThru();
const mockStore = configureStore();

describe('routes/team/team', () => {
  let context;
  let render404;
  let team;
  let landingProxy;

  beforeEach(() => {
    team = {
      id: 77
    };
    context = {
      params: {},
      query: {},
      store: mockStore({
        team,
        user: {
          id: 1
        }
      })
    };
  });

  describe('when user is a guest', () => {
    let result;
    beforeEach(() => {
      render404 = 'render404';
      landingProxy = proxyquireStrict('./index', {
        '../../../helpers/hasRole': mockEsmodule({
          default: () => false,
        }),
        '../../helpers/renderIfHasName': mockEsmodule({
          default: (_, cb) => cb(),
        }),
        '../../helpers/render404': mockEsmodule({
          default: () => render404,
        })
      }).default;
      result = landingProxy(context);
    });

    it('renders 404', () => {
      expect(result).to.eq(render404);
    });
  });

  describe('when user is at least a member', () => {
    let result;
    beforeEach(() => {
      landingProxy = proxyquireStrict('./index', {
        '../../../helpers/hasRole': mockEsmodule({
          default: () => true,
        }),
        '../../helpers/renderIfHasName': mockEsmodule({
          default: (_, cb) => cb(),
        })
      }).default;
      result = landingProxy(context);
    });

    it('renders team', () => {
      expect(result).to.have.keys('component', 'chunks', 'map', 'title');
    });
  });
});
