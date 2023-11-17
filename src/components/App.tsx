/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

import StyleContext, { InsertCSS } from "isomorphic-style-loader/StyleContext";
import PropTypes from "prop-types";
import React from "react";
import { ComponentChildren } from "preact";
import { Provider as ReduxProvider } from "react-redux";
import { Libraries, Loader } from "@googlemaps/js-api-loader";
import { AppContext } from "../interfaces";
import GoogleMapsLoaderContext from "./GoogleMapsLoaderContext/GoogleMapsLoaderContext";

const ContextType = {
  // Enables critical path CSS rendering
  // https://github.com/kriasoft/isomorphic-style-loader
  insertCss: PropTypes.func.isRequired,
  googleApiKey: PropTypes.string.isRequired,
  pathname: PropTypes.string.isRequired,
  query: PropTypes.object,
  store: PropTypes.object.isRequired,
};

interface AppProps {
  children?: ComponentChildren;
  context: AppContext;
}

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
class App extends React.PureComponent<AppProps> {
  loaderContextValue: {
    loader: Loader;
  };

  styleContextValue: {
    insertCss: InsertCSS;
  };

  static childContextTypes = ContextType;

  static defaultProps = {
    children: null,
  };

  constructor(props: AppProps) {
    super(props);

    this.loaderContextValue = {
      loader: new Loader({
        apiKey: this.props.context.googleApiKey,
        version: "weekly",
        libraries: ["places", "geocoding"] as Libraries,
      }),
    };

    this.styleContextValue = { insertCss: props.context.insertCss };
  }

  getChildContext() {
    return this.props.context;
  }

  render() {
    // NOTE: If you need to add or modify header, footer etc. of the app,
    // please do that inside the Layout component.
    return (
      <ReduxProvider store={this.props.context.store}>
        <GoogleMapsLoaderContext.Provider value={this.loaderContextValue}>
          <StyleContext.Provider value={this.styleContextValue}>
            {this.props.children}
          </StyleContext.Provider>
        </GoogleMapsLoaderContext.Provider>
      </ReduxProvider>
    );
  }
}

export default App;
