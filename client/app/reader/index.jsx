import React from 'react';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware, compose } from 'redux';
import thunk from 'redux-thunk';
import DecisionReviewer from './DecisionReviewer';
import readerReducer from './reducer';

const initialState = {
  ui: {
    pdf: {},
    pdfSidebar: {
      showTagErrorMsg: false,
      hidePdfSidebar: false
    },
    pdfList: {
      lastReadDocId: null,
      filters: {
        category: {}
      },
      dropdowns: {
        category: false
      }
    }
  },
  documents: {}
};

  // eslint-disable-next-line no-underscore-dangle
const composeEnhancers = window.__REDUX_DEVTOOLS_EXTENSION_COMPOSE__ || compose;
const store =
  createStore(readerReducer, initialState, composeEnhancers(applyMiddleware(thunk)));

if (module.hot) {
  // Enable Webpack hot module replacement for reducers
  module.hot.accept('./reducer', () => {
    /* eslint-disable global-require */
    const nextRootReducer = require('./reducer').default;
    /* eslint-enable global-require */

    store.replaceReducer(nextRootReducer);
  });
}

const Reader = (props) => {
  return <Provider store={store}>
      <DecisionReviewer {...props} />
  </Provider>;
};

export default Reader;
