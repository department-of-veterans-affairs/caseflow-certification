import request from 'superagent';
import nocache from 'superagent-no-cache';
import ReactOnRails from 'react-on-rails';
import StringUtil from './StringUtil';
import _ from 'lodash';
import { timeFunctionPromise } from '../util/PerfDebug';

export const STANDARD_API_TIMEOUT_MILLISECONDS = 60 * 1000;
export const RESPONSE_COMPLETE_LIMIT_MILLISECONDS = 5 * 60 * 1000;

export const TIMEOUT_SETTINGS = {
  response: STANDARD_API_TIMEOUT_MILLISECONDS,
  deadline: RESPONSE_COMPLETE_LIMIT_MILLISECONDS
};

const makeSendAnalyticsTimingFn = (httpVerbName) => (timeElapsedMs, url, options, endpointName) => {
  if (endpointName) {
    window.analyticsTiming({
      timingCategory: 'api-request',
      timingVar: endpointName,
      timingValue: timeElapsedMs,
      timingLabel: httpVerbName.toLowerCase()
    });
  }
};

const timeApiRequest = (httpFn, httpVerbName) => timeFunctionPromise(httpFn, makeSendAnalyticsTimingFn(httpVerbName));

// Default headers needed to talk with rails server.
// Including rails authenticity token
export const getHeadersObject = (options = {}) => {
  let headers = Object.assign({},
    {
      Accept: 'application/json',
      'Content-Type': 'application/json'
    },
    ReactOnRails.authenticityHeaders(),
    options);

  return headers;
};

const httpMethods = {
  delete(url, options = {}) {
    return request.
      delete(url).
      set(getHeadersObject(options.headers)).
      send(options.data).
      use(nocache);
  },

  get(url, options = {}) {
    let promise = request.
      get(url).
      set(getHeadersObject(options.headers)).
      query(options.query);

    if (options.timeout) {
      promise.timeout(TIMEOUT_SETTINGS);
    }

    if (options.responseType) {
      promise.responseType(options.responseType);
    }

    if (options.withCredentials) {
      promise.withCredentials();
    }

    if (options.cache) {
      return promise;
    }

    return promise.
      use(nocache);
  },

  patch(url, options = {}) {
    return request.
      post(url).
      set(getHeadersObject({ 'X-HTTP-METHOD-OVERRIDE': 'patch' })).
      send(options.data).
      use(nocache);
  },

  post(url, options = {}) {
    return request.
      post(url).
      set(getHeadersObject(options.headers)).
      send(options.data).
      use(nocache);
  },

  put(url, options = {}) {
    return request.
      put(url).
      set(getHeadersObject(options.headers)).
      send(options.data).
      use(nocache);
  }
};

// TODO(jd): Fill in other HTTP methods as needed
const ApiUtil = {

  // Converts camelCase to snake_case
  convertToSnakeCase(data) {
    if (!_.isObject(data)) {
      return data;
    }
    let result = {};

    for (let key in data) {
      if ({}.hasOwnProperty.call(data, key)) {
        let snakeKey = StringUtil.camelCaseToSnakeCase(key);

        // assign value to new object
        result[snakeKey] = this.convertToSnakeCase(data[key]);
      }
    }

    return result;
  },

  ..._.mapValues(httpMethods, timeApiRequest)
};

export default ApiUtil;
