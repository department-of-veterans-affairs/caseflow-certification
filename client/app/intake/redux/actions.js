import { ACTIONS } from '../constants';
import ApiUtil from '../../util/ApiUtil';
import { formatDateStringForApi } from '../../util/DateUtil';

const analytics = true;

export const startNewIntake = () => ({
  type: ACTIONS.START_NEW_INTAKE,
  meta: { analytics }
});

export const setFileNumberSearch = (fileNumber) => ({
  type: ACTIONS.SET_FILE_NUMBER_SEARCH,
  payload: {
    fileNumber
  }
});

export const doFileNumberSearch = (fileNumberSearch) => (dispatch) => {
  dispatch({
    type: ACTIONS.FILE_NUMBER_SEARCH_START,
    meta: { analytics }
  });

  return ApiUtil.post('/intake', { data: { file_number: fileNumberSearch } }).
    then(
      (response) => {
        const responseObject = JSON.parse(response.text);

        dispatch({
          type: ACTIONS.FILE_NUMBER_SEARCH_SUCCEED,
          payload: {
            intake: responseObject
          },
          meta: { analytics }
        });
      },
      (error) => {
        const responseObject = JSON.parse(error.response.text);

        dispatch({
          type: ACTIONS.FILE_NUMBER_SEARCH_FAIL,
          payload: {
            errorCode: responseObject.error_code,
            errorData: responseObject.error_data || {}
          },
          meta: { analytics }
        });

        throw error;
      }
    );
};

export const setOptionSelected = (optionSelected) => ({
  type: ACTIONS.SET_OPTION_SELECTED,
  payload: {
    optionSelected
  },
  meta: { 
    analytics: {
      label: optionSelected
    } 
  }
});

export const setReceiptDate = (receiptDate) => ({
  type: ACTIONS.SET_RECEIPT_DATE,
  payload: {
    receiptDate
  }
});

export const submitReview = (rampElection) => (dispatch) => {
  dispatch({
    type: ACTIONS.SUBMIT_REVIEW_START,
    meta: { analytics }
  });

  const data = {
    option_selected: rampElection.optionSelected,
    receipt_date: formatDateStringForApi(rampElection.receiptDate)
  };

  return ApiUtil.patch(`/intake/ramp/${rampElection.intakeId}`, { data }).
    then(
      () => dispatch({ 
        type: ACTIONS.SUBMIT_REVIEW_SUCCEED,
        meta: { analytics }
      }),
      (error) => {
        const responseObject = JSON.parse(error.response.text);

        dispatch({
          type: ACTIONS.SUBMIT_REVIEW_FAIL,
          payload: {
            responseErrorCodes: responseObject.error_codes
          },
          meta: { analytics }
        });

        throw error;
      }
    );
};

export const completeIntake = (rampElection) => (dispatch) => {
  if (!rampElection.finishConfirmed) {
    dispatch({
      type: ACTIONS.COMPLETE_INTAKE_NOT_CONFIRMED
    });

    return;
  }

  dispatch({
    type: ACTIONS.COMPLETE_INTAKE_START,
    meta: { analytics }
  });

  return ApiUtil.patch(`/intake/ramp/${rampElection.intakeId}/complete`).
    then(
      () => dispatch({ 
        type: ACTIONS.COMPLETE_INTAKE_SUCCEED,
        meta: { analytics } 
      }),
      (error) => {
        dispatch({ 
          type: ACTIONS.COMPLETE_INTAKE_FAIL,
          meta: { analytics } 
        });
        throw error;
      }
    );
};

export const toggleCancelModal = () => ({
  type: ACTIONS.TOGGLE_CANCEL_MODAL,
  meta: { 
    analytics: {
      label: (nextState) => nextState.cancelModalVisible ? 'show' : 'hide'
    } 
  }
});

export const submitCancel = (rampElection) => (dispatch) => {
  dispatch({
    type: ACTIONS.CANCEL_INTAKE_START,
    meta: { analytics }
  });

  return ApiUtil.delete(`/intake/ramp/${rampElection.intakeId}`).
    then(
      () => dispatch({ 
        type: ACTIONS.CANCEL_INTAKE_SUCCEED,
        meta: { analytics }
       }),
      (error) => {
        dispatch({ 
          type: ACTIONS.CANCEL_INTAKE_FAIL,
          meta: { analytics } 
        });
        throw error;
      }
    );
};

export const confirmFinishIntake = (isConfirmed) => ({
  type: ACTIONS.CONFIRM_FINISH_INTAKE,
  payload: { isConfirmed },
  meta: { 
    analytics: {
      label: isConfirmed ? 'confirmed' : 'not-confirmed'
    } 
  }
});
