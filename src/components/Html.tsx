/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-2016 Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

import React, { Component } from "react";
import serialize from "serialize-javascript";
import * as config from "../config";
import { App } from "../interfaces";

/* eslint-disable react/no-danger */

export interface HtmlProps {
  app?: App;
  title: string;
  ogTitle?: string;
  description: string;
  root?: string;
  styles?: { id: string; cssText: string }[];
  scripts?: string[];
  children: string;
}

class Html extends Component<HtmlProps> {
  static defaultProps = {
    app: {},
    ogTitle: "",
    styles: [],
    scripts: [],
    root: "",
  };

  render() {
    const {
      app,
      title,
      ogTitle,
      description,
      root,
      styles,
      scripts,
      children,
    } = this.props;

    return (
      <html className="no-js" lang="en">
        <head>
          {config.analytics.googleMeasurementId && (
            <>
              <script
                key="ga_script"
                async
                src={`https://www.googletagmanager.com/gtag/js?id=${config.analytics.googleMeasurementId}`}
              />

              <script
                key="ga_init"
                dangerouslySetInnerHTML={{
                  __html: `
window.dataLayer = window.dataLayer || [];
function gtag(){dataLayer.push(arguments);}
gtag('js', new Date());
gtag('config', '${config.analytics.googleMeasurementId}');
`,
                }}
              />
            </>
          )}
          <meta charSet="utf-8" />
          <meta httpEquiv="x-ua-compatible" content="ie=edge" />
          <title>{title}</title>
          <meta name="description" content={description} />
          <meta property="og:title" content={ogTitle} />
          <meta property="og:description" content={description} />
          <meta property="og:image" content={`${root}/tile.png`} />
          <meta property="og:site_name" content="Lab Zero" />
          <meta property="og:url" content={root} />
          <meta property="og:type" content="website" />
          <meta property="twitter:card" content="summary" />
          <meta property="twitter:site" content="labzero" />
          <meta property="twitter:image" content={`${root}/tile.png`} />
          <meta name="theme-color" content="#FFC0CB" />
          <meta
            name="viewport"
            content="width=device-width, initial-scale=1, user-scalable=no"
          />
          <link
            rel="stylesheet"
            href="https://fonts.googleapis.com/css?family=Nunito:400,900"
          />
          {scripts!.map((script) => (
            <link key={script} rel="preload" href={script} as="script" />
          ))}
          <link rel="manifest" href="/site.webmanifest" />
          <link rel="apple-touch-icon" href="/icon.png" />
          {styles!.map((style) => (
            <style
              key={style.id}
              id={style.id}
              dangerouslySetInnerHTML={{ __html: style.cssText }}
            />
          ))}
        </head>
        <body>
          <div id="app" dangerouslySetInnerHTML={{ __html: children }} />
          <script
            dangerouslySetInnerHTML={{ __html: `window.App=${serialize(app)}` }}
          />
          {!module.hot && (
            <script
              dangerouslySetInnerHTML={{
                __html:
                  "if ('serviceWorker' in navigator) { window.addEventListener('load', () => { navigator.serviceWorker.register('/service-worker.js').then(function(registration) {registration.addEventListener('updatefound', () => {window.swUpdate = true; }); }); }); }",
              }}
            />
          )}
          {scripts!.map((script) => (
            <script key={script} src={script} />
          ))}
        </body>
      </html>
    );
  }
}

export default Html;
