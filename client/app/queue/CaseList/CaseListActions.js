import ApiUtil from '../../util/ApiUtil';
import * as Constants from './actionTypes';
import _ from 'lodash';

export const clearCaseListSearch = () => ({
  type: Constants.CLEAR_CASE_LIST_SEARCH
});

export const setCaseListSearch = (searchQuery) => ({
  type: Constants.SET_CASE_LIST_SEARCH,
  payload: { searchQuery }
});

export const setShouldUseQueueSearch = (bool) => ({
  type: Constants.SET_SHOULD_USE_QUEUE_SEARCH,
  payload: { bool }
});

export const requestAppealUsingVeteranId = () => ({
  type: Constants.REQUEST_APPEAL_USING_VETERAN_ID
});

export const fetchedNoAppealsUsingVeteranId = (searchQuery) => ({
  type: Constants.RECEIVED_NO_APPEALS_USING_VETERAN_ID,
  payload: { searchQuery }
});

export const onReceiveAppealsUsingVeteranId = (appeals) => ({
  type: Constants.RECEIVED_APPEALS_USING_VETERAN_ID_SUCCESS,
  payload: { appeals }
});

export const fetchAppealUsingVeteranIdFailed = () => ({
  type: Constants.RECEIVED_APPEALS_USING_VETERAN_ID_FAILURE
});

export const fetchAppealsUsingVeteranId = (veteranId) =>
  (dispatch) => {
    ApiUtil.get('/appeals', {
      headers: { 'veteran-id': veteranId }
    }).
      then((response) => {
        const returnedObject = JSON.parse(response.text);

        const shouldUseAppealSearch = returnedObject.hasOwnProperty("shouldUseAppealSearch") && returnedObject.shouldUseAppealSearch;
        dispatch(setShouldUseQueueSearch(shouldUseAppealSearch));

        // TODO: AppealsController.index returns the data with a few extraneous elements. Remove this fix when we change
        // the data structure we return to collapse the data and attribute elements.
        // { appeals: {
        //   data: [
        //     { attributes: {...}, ... },
        //     { attributes: {...}, ... },
        //     { attributes: {...}, ... }
        //     ]
        //   }
        // }
        const appeals = returnedObject.appeals.data.map(a => {
          const attrs = a.attributes;
          delete a.attributes;
          return Object.assign(a, attrs);
        });
        if (_.size(appeals) === 0) {
          dispatch(fetchedNoAppealsUsingVeteranId(veteranId));
        } else {
          dispatch(onReceiveAppealsUsingVeteranId(appeals));
        }
      }, () => {
        dispatch(fetchAppealUsingVeteranIdFailed());
      });
  };
