import React from 'react';
import _ from 'lodash';
import StringUtil from '../util/StringUtil';
import {
  redText,
  USER_ROLES
} from './constants';
import ISSUE_INFO from '../../constants/ISSUE_INFO.json';
import DIAGNOSTIC_CODE_DESCRIPTIONS from '../../constants/DIAGNOSTIC_CODE_DESCRIPTIONS.json';
import VACOLS_DISPOSITIONS_BY_ID from '../../constants/VACOLS_DISPOSITIONS_BY_ID.json';
import DECISION_TYPES from '../../constants/APPEAL_DECISION_TYPES.json';

export const associateTasksWithAppeals = (serverData = {}) => {
  const {
    appeals: { data: appeals },
    tasks: { data: tasks }
  } = serverData;

  _.each(tasks, (task) => {
    task.appealId = task.id;
  });

  const tasksById = _.keyBy(tasks, 'id');
  const appealsById = _.keyBy(appeals, 'attributes.vacols_id');

  return {
    appeals: appealsById,
    tasks: tasksById
  };
};

/*
* Sorting hierarchy:
*  1 AOD vets and CAVC remands
*  2 All other appeals (originals, remands, etc)
*
*  Sort by docket date (form 9 date) oldest to
*  newest within each group
*/
export const sortTasks = ({ tasks = {}, appeals = {} }) => {
  const partitionedTasks = _.partition(tasks, (task) =>
    appeals[task.appealId].attributes.aod || appeals[task.appealId].attributes.type === 'Court Remand'
  );

  _.each(partitionedTasks, _.sortBy('attributes.docket_date'));
  _.each(partitionedTasks, _.reverse);

  return _.flatten(partitionedTasks);
};

export const renderAppealType = (appeal) => {
  const {
    attributes: { aod, type }
  } = appeal;
  const cavc = type === 'Court Remand';

  return <React.Fragment>
    {aod && <span><span {...redText}>AOD</span>, </span>}
    {cavc ? <span {...redText}>CAVC</span> : <span>{type}</span>}
  </React.Fragment>;
};

export const getDecisionTypeDisplay = (decision = {}) => {
  const {
    type: decisionType
  } = decision;

  switch (decisionType) {
  case DECISION_TYPES.OMO_REQUEST:
    return 'OMO';
  case DECISION_TYPES.DRAFT_DECISION:
    return 'Draft Decision';
  default:
    return StringUtil.titleCase(decisionType);
  }
};

export const getIssueProgramDescription = (issue) => _.get(ISSUE_INFO[issue.program], 'description', '');
export const getIssueTypeDescription = (issue) => {
  const {
    program,
    type
  } = issue;

  return _.get(ISSUE_INFO[program].levels, `${type}.description`);
};

export const getIssueDiagnosticCodeLabel = (code) => {
  const readableLabel = DIAGNOSTIC_CODE_DESCRIPTIONS[code];

  if (!readableLabel) {
    return false;
  }

  return `${code} - ${readableLabel.staff_description}`;
};

/**
 * For attorney checkout flow, filter out already-decided issues. Undecided
 * disposition IDs are all numerical (1-9), decided IDs are alphabetical (A-X).
 *
 * @param {Array} issues
 * @returns {Array}
 */
export const getUndecidedIssues = (issues) => _.filter(issues, (issue) =>
  !issue.disposition || (Number(issue.disposition) && issue.disposition in VACOLS_DISPOSITIONS_BY_ID)
);

/**
 * @param {Object} decision
 * @param {String} userRole
 * @param {Array} issues
 * @param {Object} args
 * @returns {Object}
 */
export const buildCaseReviewPayload = (decision, userRole, issues, args = {}) => {
  const payload = {
    data: {
      tasks: {
        type: `${userRole}CaseReview`,
        ...decision.opts
      }
    }
  };
  let issueList = issues;

  if (userRole === USER_ROLES.ATTORNEY) {
    issueList = getUndecidedIssues(issues);

    _.extend(payload.data.tasks, { document_type: decision.type });
  } else {
    args.factors_not_considered = _.keys(args.factors_not_considered);
    args.areas_for_improvement = _.keys(args.areas_for_improvement);

    _.extend(payload.data.tasks, args);
  }

  payload.data.tasks.issues = issueList.map((issue) => _.extend({},
    _.pick(issue, ['vacols_sequence_id', 'remand_reasons', 'type', 'readjudication']),
    { disposition: _.capitalize(issue.disposition) }
  ));

  return payload;
};
