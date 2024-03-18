/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

import type { Agent } from "https";
import { Fetch, FetchWithCache, WindowWithApp } from "./interfaces";

declare const window: WindowWithApp;

type Options = {
  baseUrl: string;
  cookie?: string;
  agent?: Agent;
};

/**
 * Creates a wrapper function around the HTML5 Fetch API that provides
 * default arguments to fetch(...) and is intended to reduce the amount
 * of boilerplate code in the application.
 * https://developer.mozilla.org/docs/Web/API/Fetch_API/Using_Fetch
 */
function createFetch(
  fetch: Fetch,
  { agent, baseUrl, cookie }: Options
): FetchWithCache {
  // NOTE: Tweak the default options to suite your application needs
  const defaults = {
    agent,
    mode: baseUrl ? "cors" : "same-origin",
    credentials: baseUrl ? "include" : "same-origin",
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
      ...(cookie ? { Cookie: cookie } : null),
    },
  };

  return async (url, cacheConfig, options) => {
    // Instead of making an actual HTTP request to the API, use
    // hydrated data available during the initial page load.
    if (typeof window !== "undefined" && window.App.cache !== undefined) {
      // eslint-disable-next-line no-param-reassign
      cacheConfig[url] = window.App.cache[url];
      delete window.App.cache[url];
    }

    if (cacheConfig[url]) {
      return Promise.resolve(cacheConfig[url]);
    }

    const response = await (url.startsWith("/api")
      ? fetch(`${baseUrl}${url}`, {
          ...defaults,
          ...options,
          headers: {
            ...defaults.headers,
            ...(options && options.headers),
          },
        })
      : fetch(url, options));

    const json = await response.json();
    // eslint-disable-next-line no-param-reassign
    cacheConfig[url] = json;
    return json;
  };
}

export default createFetch;
