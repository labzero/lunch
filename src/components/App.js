/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

import StyleContext from 'isomorphic-style-loader/StyleContext';
import PropTypes from 'prop-types';
import React, { Children } from 'react';
import { Provider as ReduxProvider } from 'react-redux';
import IntlProviderContainer from './IntlProvider/IntlProviderContainer';

const ContextType = {
  // Enables critical path CSS rendering
  // https://github.com/kriasoft/isomorphic-style-loader
  insertCss: PropTypes.func.isRequired,
  // Universal HTTP client
  fetch: PropTypes.func.isRequired,
  pathname: PropTypes.string.isRequired,
  query: PropTypes.object,
  store: PropTypes.object.isRequired,
  // Integrate Redux
  // http://redux.js.org/docs/basics/UsageWithReact.html
  ...ReduxProvider.childContextTypes,
};

/**
 * The top-level React component setting context (global) variables
 * that can be accessed from all the child components.
 *
 * https://facebook.github.io/react/docs/context.html
 *
 * Usage example:
 *
 *   const context = {
 *     history: createBrowserHistory(),
 *     store: createStore(),
 *   };
 *
 *   ReactDOM.render(
 *     <App context={context}>
 *       <Layout>
 *         <LandingPage />
 *       </Layout>
 *     </App>,
 *     container,
 *   );
 */
class App extends React.PureComponent {
  static propTypes = {
    context: PropTypes.shape(ContextType).isRequired,
    children: PropTypes.element.isRequired,
  };

  static childContextTypes = ContextType;

  getChildContext() {
    return this.props.context;
  }

  render() {
    // NOTE: If you need to add or modify header, footer etc. of the app,
    // please do that inside the Layout component.
    return (
      <StyleContext.Provider
        value={{ insertCss: this.props.context.insertCss }}
      >
        <ReduxProvider store={this.props.context.store}>
          <IntlProviderContainer>
            {Children.only(this.props.children)}
          </IntlProviderContainer>
        </ReduxProvider>
      </StyleContext.Provider>
    );
  }
}

export default App;
