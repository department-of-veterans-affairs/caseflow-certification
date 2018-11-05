import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { sprintf } from 'sprintf-js';

import TabWindow from '../components/TabWindow';
import TaskTable from './components/TaskTable';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import type { State } from './types/state';
import type { TaskWithAppeal } from './types/models';

import {
  getUnassignedOrganizationalTasks,
  getOnHoldOrganizationalTasks,
  getCompletedOrganizationalTasks,
  tasksByOrganization
} from './selectors';

import { clearCaseSelectSearch } from '../reader/CaseSelect/CaseSelectActions';

import { fullWidth } from './constants';
import COPY from '../../COPY.json';

class OrganizationQueue extends React.PureComponent {
  componentDidMount = () => {
    this.props.clearCaseSelectSearch();
  }

  render = () => {
    const tabs = [
      {
        label: sprintf(
          COPY.ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TAB_TITLE,
          this.props.numberOfTasks.unassigned),
        page: <UnassignedTasksTab organizationName={this.props.organizationName} />
      },
      {
        label: sprintf(
          COPY.ORGANIZATIONAL_QUEUE_PAGE_ASSIGNED_TAB_TITLE,
          this.props.numberOfTasks.onHold),
        page: <AssignedTasksTab organizationName={this.props.organizationName} />
      },
      {
        label: COPY.ORGANIZATIONAL_QUEUE_PAGE_COMPLETE_TAB_TITLE,
        page: <CompletedTasksTab organizationName={this.props.organizationName} />
      }
    ];

    return <AppSegment filledBackground>
      <div>
        <h1 {...fullWidth}>{sprintf(COPY.ORGANIZATION_QUEUE_TABLE_TITLE, this.props.organizationName)}</h1>
        <TabWindow
          name="tasks-organization-queue"
          tabs={tabs}
        />
      </div>
    </AppSegment>;
  };
}

OrganizationQueue.propTypes = {
  tasks: PropTypes.array.isRequired
};

const mapStateToProps = (state) => {
  return ({
    numberOfTasks: {
      unassigned: getUnassignedOrganizationalTasks(state).length,
      onHold: getOnHoldOrganizationalTasks(state).length,
      completed: getCompletedOrganizationalTasks(state).length
    },
    tasks: tasksByOrganization(state)
  });
};

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    clearCaseSelectSearch
  }, dispatch)
});

export default connect(mapStateToProps, mapDispatchToProps)(OrganizationQueue);

const UnassignedTasksTab = connect(
  (state: State) => ({ tasks: getUnassignedOrganizationalTasks(state) }))(
  (props: { tasks: Array<TaskWithAppeal> }) => {
    return <React.Fragment>
      <p>{sprintf(COPY.COLOCATED_QUEUE_PAGE_UNASSIGNED_TASKS_DESCRIPTION, props.organizationName)}</p>
      <TaskTable
        includeDetailsLink
        includeTask
        includeType
        includeDocketNumber
        includeDaysWaiting
        includeReaderLink
        tasks={props.tasks}
      />
    </React.Fragment>;
  });

const AssignedTasksTab = connect(
  (state: State) => ({ tasks: getOnHoldOrganizationalTasks(state) }))(
  (props: { tasks: Array<TaskWithAppeal> }) => {
    return <React.Fragment>
      <p>{sprintf(COPY.COLOCATED_QUEUE_PAGE_ASSIGNED_TASKS_DESCRIPTION, props.organizationName)}</p>
      <TaskTable
        includeDetailsLink
        includeTask
        includeType
        includeDocketNumber
        includeDaysWaiting
        includeReaderLink
        tasks={props.tasks}
      />
    </React.Fragment>;
  });

const CompletedTasksTab = connect(
  (state: State) => ({ tasks: getCompletedOrganizationalTasks(state) }))(
  (props: { tasks: Array<TaskWithAppeal> }) => {
    return <React.Fragment>
      <p>{sprintf(COPY.COLOCATED_QUEUE_PAGE_COMPLETE_TASKS_DESCRIPTION, props.organizationName)}</p>
      <TaskTable
        includeDetailsLink
        includeTask
        includeType
        includeDocketNumber
        includeDaysWaiting
        includeReaderLink
        tasks={props.tasks}
      />
    </React.Fragment>;
  });
