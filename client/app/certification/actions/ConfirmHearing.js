import * as Constants from '../constants/constants';
import ApiUtil from '../../util/ApiUtil';
import * as CertificationAction from './Certification';


export const updateProgressBar = () => ({
  type: Constants.UPDATE_PROGRESS_BAR,
  payload: {
    currentSection: Constants.progressBarSections.CONFIRM_HEARING
  }
});

export const onHearingDocumentChange = (hearingDocumentIsInVbms) => ({
  type: Constants.CHANGE_VBMS_HEARING_DOCUMENT,
  payload: {
    hearingDocumentIsInVbms
  }
});

export const onTypeOfForm9Change = (form9Type) => ({
  type: Constants.CHANGE_TYPE_OF_FORM9,
  payload: {
    form9Type
  }
});

export const onHearingPreferenceChange = (hearingPreference) => ({
  type: Constants.CHANGE_TYPE_OF_HEARING,
  payload: {
    hearingPreference
  }
});

export const certificationUpdateFailure = () => ({
  type: Constants.CERTIFICATION_UPDATE_FAILURE
});

export const certificationUpdateSuccess = () => ({
  type: Constants.CERTIFICATION_UPDATE_SUCCESS
});

export const certificationUpdateStart = (params, dispatch) => {

  const hearingDocumentIsInVbms =
      params.hearingDocumentIsInVbms === Constants.vbmsHearingDocument.FOUND;

  const form9Type = hearingDocumentIsInVbms ? null : params.form9Type;

  // Translate camelcase React names into snake case
  // Rails key names.
  /* eslint-disable camelcase */
  const update = {
    hearing_change_doc_found_in_vbms: hearingDocumentIsInVbms,
    form9_type: form9Type,
    hearing_preference: params.hearingPreference
  };
  /* eslint-enable "camelcase" */

  ApiUtil.put(`/certifications/${params.vacolsId}/update_v2`, { data: { update } }).
    then(() => {
      dispatch(certificationUpdateSuccess());
    }, (err) => {
      dispatch(certificationUpdateFailure(err));
      dispatch(CertificationAction.toggleHeader());
      dispatch(CertificationAction.updateErrorNotice(JSON.parse(err.response.text).errors[0]));
    });

  return {
    type: Constants.CERTIFICATION_UPDATE_REQUEST,
    payload: {
      update
    }
  };
};
