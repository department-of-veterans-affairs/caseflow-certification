// actions
//
export const UPDATE_PROGRESS_BAR = 'UPDATE_PROGRESS_BAR';
export const TOGGLE_CANCELLATION_MODAL = 'TOGGLE_CANCELLATION_MODAL';
export const CHANGE_VBMS_HEARING_DOCUMENT = 'CHANGE_VBMS_HEARING_DOCUMENT';
export const CHANGE_TYPE_OF_FORM9 = 'CHANGE_TYPE_OF_FORM9';
export const CHANGE_TYPE_OF_HEARING = 'CHANGE_TYPE_OF_HEARING';

export const CHANGE_REPRESENTATIVE_NAME = 'CHANGE_REPRESENTATIVE_NAME';
export const CHANGE_REPRESENTATIVE_TYPE = 'CHANGE_REPRESENTATIVE_TYPE';
export const CHANGE_OTHER_REPRESENTATIVE_TYPE = 'CHANGE_OTHER_REPRESENTATIVE_TYPE';
export const CHANGE_POA_MATCHES = 'CHANGE_POA_MATCHES';
export const CHANGE_POA_CORRECT_LOCATION = 'CHANGE_POA_CORRECT_LOCATION';

export const CHANGE_SIGN_AND_CERTIFY_FORM = 'CHANGE_SIGN_AND_CERTIFY_FORM';

export const CERTIFICATION_UPDATE_REQUEST = 'CERTIFICATION_UPDATE_REQUEST';
export const HANDLE_SERVER_ERROR = 'HANDLE_SERVER_ERROR';
export const CERTIFICATION_UPDATE_SUCCESS = 'CERTIFICATION_UPDATE_SUCCESS';

export const SHOW_VALIDATION_ERRORS = 'SHOW_VALIDATION_ERRORS';

export const RESET_STATE = 'RESET_STATE';

// types of hearings
export const hearingPreferences = {
  VIDEO: 'VIDEO',
  TRAVEL_BOARD: 'TRAVEL_BOARD',
  WASHINGTON_DC: 'WASHINGTON_DC',
  HEARING_TYPE_NOT_SPECIFIED: 'HEARING_TYPE_NOT_SPECIFIED',
  NO_HEARING_DESIRED: 'NO_HEARING_DESIRED',
  HEARING_CANCELLED: 'HEARING_CANCELLED',
  NO_BOX_SELECTED: 'NO_BOX_SELECTED'
};

// form9 values
export const form9Types = {
  FORMAL_FORM9: 'FORMAL_FORM9',
  INFORMAL_FORM9: 'INFORMAL_FORM9'
};

// representation for the appellant
export const representativeTypes = {
  ATTORNEY: 'ATTORNEY',
  AGENT: 'AGENT',
  ORGANIZATION: 'ORGANIZATION',
  NONE: 'NONE',
  // TODO: should "Other be a real type"?
  OTHER: 'OTHER'
};

// was a hearing document found in VBMS?
export const vbmsHearingDocument = {
  FOUND: 'FOUND',
  NOT_FOUND: 'NOT_FOUND'
};

export const progressBarSections = {
  CHECK_DOCUMENTS: 'CHECK_DOCUMENTS',
  CONFIRM_CASE_DETAILS: 'CONFIRM_CASE_DETAILS',
  CONFIRM_HEARING: 'CONFIRM_HEARING',
  SIGN_AND_CERTIFY: 'SIGN_AND_CERTIFY'
};

export const certifyingOfficialTitles = {
  DECISION_REVIEW_OFFICER: 'DECISION_REVIEW_OFFICER',
  RATING_SPECIALIST: 'RATING_SPECIALIST',
  VETERANS_SERVICE_REPRESENTATIVE: 'VETERANS_SERVICE_REPRESENTATIVE',
  CLAIMS_ASSISTANT: 'CLAIMS_ASSISTANT',
  OTHER: 'OTHER'
};

// does the POA information match?
export const poaMatches = {
  MATCH: 'MATCH',
  NO_MATCH: 'NO_MATCH'
};

export const poaCorrectLocation = {
  VBMS: 'VBMS',
  VACOLS: 'VACOLS',
  NONE: 'NONE'
};
