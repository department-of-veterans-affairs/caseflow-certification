// @flow
import { css } from 'glamor';
import moment from 'moment';
import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';
import _ from 'lodash';

import { tasksForAppealAssignedToUserSelector } from './selectors';
import CaseDetailsDescriptionList from './components/CaseDetailsDescriptionList';
import SelectCheckoutFlowDropdown from './components/SelectCheckoutFlowDropdown';
import JudgeActionsDropdown from './components/JudgeActionsDropdown';
import COPY from '../../COPY.json';
import { USER_ROLES } from './constants';
import { COLORS } from '../constants/AppConstants';
import { renderLegacyAppealType } from './utils';
import { DateString } from '../util/DateUtil';
import type { LegacyAppeal, Task } from './types/models';
import type { State, AttorneysOfJudge } from './types/state';

const snapshotParentContainerStyling = css({
  backgroundColor: COLORS.GREY_BACKGROUND,
  display: 'flex',
  flexWrap: 'wrap',
  lineHeight: '3rem',
  marginTop: '3rem',
  padding: '2rem 0',
  '& > div': { padding: '0 3rem 0 0' },
  '& > div:not(:last-child)': { borderRight: `1px solid ${COLORS.GREY_LIGHT}` },
  '& > div:first-child': { paddingLeft: '3rem' },

  '& .Select': { maxWidth: '100%' }
});

const headingStyling = css({
  marginBottom: '0.5rem'
});

const snapshotChildResponsiveWrapFixStyling = css({
  '@media(max-width: 1200px)': {
    '& > .usa-width-one-half': {
      borderTop: `1px solid ${COLORS.GREY_LIGHT}`,
      margin: '2rem 3rem 0 3rem',
      marginRight: '3rem !important',
      paddingTop: '2rem',
      width: '100%'
    },
    '& > div:nth-child(2)': { borderRight: 'none' }
  }
});

type Params = {|
  appeal: LegacyAppeal,
  task: Task,
  hideDropdown?: boolean
|};

type Props = Params & {|
  featureToggles: Object,
  appealsAssignedToCurrentUser: Array<LegacyAppeal>,
  userRole: string,
  attorneysOfJudge: AttorneysOfJudge
|};

export class CaseSnapshot extends React.PureComponent<Props> {
  daysSinceTaskAssignmentListItem = () => {
    if (this.props.task) {
      const today = moment();
      const dateAssigned = moment(this.props.task.assignedOn);
      const dayCountSinceAssignment = today.diff(dateAssigned, 'days');

      return <React.Fragment>
        <dt>{COPY.CASE_SNAPSHOT_DAYS_SINCE_ASSIGNMENT_LABEL}</dt><dd>{dayCountSinceAssignment}</dd>
      </React.Fragment>;
    }

    return null;
  };

  taskAssignmentListItems = () => {
    const assignedToListItem = <React.Fragment>
      <dt>{COPY.CASE_SNAPSHOT_TASK_ASSIGNEE_LABEL}</dt><dd>{this.props.appeal.attributes.location_code}</dd>
    </React.Fragment>;

    if (!this.props.task) {
      return assignedToListItem;
    }

    const task = this.props.task;

    if (this.props.userRole === USER_ROLES.JUDGE) {
      if (!task.assignedByFirstName || !task.assignedByLastName || !task.documentId) {
        return assignedToListItem;
      }

      const firstInitial = String.fromCodePoint(task.assignedByFirstName.codePointAt(0));
      const nameAbbrev = `${firstInitial}. ${task.assignedByLastName}`;

      return <React.Fragment>
        <dt>{COPY.CASE_SNAPSHOT_DECISION_PREPARER_LABEL}</dt><dd>{nameAbbrev}</dd>
        <dt>{COPY.CASE_SNAPSHOT_DECISION_DOCUMENT_ID_LABEL}</dt><dd>{task.documentId}</dd>
      </React.Fragment>;
    }

    return <React.Fragment>
      { task.addedByName && <React.Fragment>
        <dt>{COPY.CASE_SNAPSHOT_TASK_ASSIGNOR_LABEL}</dt>
        <dd>{task.addedByName}</dd>
      </React.Fragment> }
      <dt>{COPY.CASE_SNAPSHOT_TASK_ASSIGNMENT_DATE_LABEL}</dt>
      <dd><DateString date={task.assignedOn} dateFormat="MM/DD/YY" /></dd>
      <dt>{COPY.CASE_SNAPSHOT_TASK_DUE_DATE_LABEL}</dt>
      <dd><DateString date={task.dueOn} dateFormat="MM/DD/YY" /></dd>
    </React.Fragment>;
  };

  showActionsSection = () => {
    if (this.props.hideDropdown) {
      return false;
    }
    if (this.props.appealsAssignedToCurrentUser) {
      return true;
    }
    if (!this.props.task) {
      return false;
    }

    return _.some(
      this.props.attorneysOfJudge, (attorney) => attorney.id === this.props.task.assignedToPgId);
  }

  render = () => {
    const {
      appeal: { attributes: appeal },
      userRole
    } = this.props;
    let CheckoutDropdown = <React.Fragment />;

    if (userRole === USER_ROLES.ATTORNEY) {
      CheckoutDropdown = <SelectCheckoutFlowDropdown appealId={appeal.external_id} />;
    } else if (userRole === USER_ROLES.JUDGE && this.props.featureToggles.judge_case_review_checkout) {
      CheckoutDropdown = <JudgeActionsDropdown appealId={appeal.external_id} />;
    }

    return <div className="usa-grid" {...snapshotParentContainerStyling} {...snapshotChildResponsiveWrapFixStyling}>
      <div className="usa-width-one-fourth">
        <h3 {...headingStyling}>{COPY.CASE_SNAPSHOT_ABOUT_BOX_TITLE}</h3>
        <CaseDetailsDescriptionList>
          <dt>{COPY.CASE_SNAPSHOT_ABOUT_BOX_TYPE_LABEL}</dt>
          <dd>{renderLegacyAppealType(this.props.appeal)}</dd>
          <dt>{COPY.CASE_SNAPSHOT_ABOUT_BOX_DOCKET_NUMBER_LABEL}</dt>
          <dd>{appeal.docket_number}</dd>
          {this.daysSinceTaskAssignmentListItem()}
        </CaseDetailsDescriptionList>
      </div>
      <div className="usa-width-one-fourth">
        <h3 {...headingStyling}>{COPY.CASE_SNAPSHOT_TASK_ASSIGNMENT_BOX_TITLE}</h3>
        <CaseDetailsDescriptionList>
          {this.taskAssignmentListItems()}
        </CaseDetailsDescriptionList>
      </div>
      {this.showActionsSection() &&
        <div className="usa-width-one-half">
          <h3>{COPY.CASE_SNAPSHOT_ACTION_BOX_TITLE}</h3>
          {CheckoutDropdown}
        </div>
      }
    </div>;
  };
}

CaseSnapshot.propTypes = {
  appeal: PropTypes.object.isRequired,
  featureToggles: PropTypes.object,
  appealsAssignedToCurrentUser: PropTypes.array,
  task: PropTypes.object,
  userRole: PropTypes.string,
  hideDropdown: PropTypes.bool
};

const mapStateToProps = (state: State, ownProps: Object) => {
  const { featureToggles, userRole } = state.ui;

  return {
    featureToggles,
    userRole,
    appealsAssignedToCurrentUser: tasksForAppealAssignedToUserSelector(state, ownProps),
    attorneysOfJudge: state.queue.attorneysOfJudge
  };
};

export default connect(mapStateToProps)(CaseSnapshot);
