/* eslint-env mocha */
import fetchMock from 'fetch-mock';
import { configure } from 'enzyme';
import Adapter from 'enzyme-adapter-react-16';

configure({ adapter: new Adapter() });

afterEach(() => {
  fetchMock.restore();
});
