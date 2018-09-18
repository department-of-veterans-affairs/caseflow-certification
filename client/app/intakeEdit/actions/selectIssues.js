import { ACTIONS, ENDPOINT_NAMES } from '../constants';
import ApiUtil from '../../util/ApiUtil';
import { formatIssues } from '../../intakeCommon/util';

const analytics = true;

export const requestIssuesUpdate = (claimId, formType, state) => (dispatch) => {
  dispatch({
    type: ACTIONS.REQUEST_ISSUES_UPDATE_START,
    meta: { analytics }
  });

  const data = formatIssues(state);
  const pathMap = {
    higher_level_review: 'higher_level_reviews',
    supplemental_claim: 'supplemental_claims'
  };

  return ApiUtil.patch(`/${pathMap[formType]}/${claimId}/update`, { data }, ENDPOINT_NAMES.REQUEST_ISSUES_UPDATE)
    .then(
      (response) => {
        const responseObject = JSON.parse(response.text);

        dispatch({
          type: ACTIONS.REQUEST_ISSUES_UPDATE_SUCCEED,
          payload: {
            ratings: responseObject.ratings,
            ratedRequestIssues: responseObject.ratedRequestIssues
          },
          meta: { analytics }
        });

        return true;
      },
      (error) => {
        let responseObject = {};

        try {
          responseObject = JSON.parse(error.response.text);
        } catch (ex) { /* pass */ }

        const responseErrorCode = responseObject.error_code;
        const responseErrorData = responseObject.error_data;

        dispatch({
          type: ACTIONS.REQUEST_ISSUES_UPDATE_FAIL,
          payload: {
            responseErrorCode,
            responseErrorData
          },
          meta: { analytics }
        });
        throw error;
      }
    );
};
