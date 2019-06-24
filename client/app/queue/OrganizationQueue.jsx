import React from 'react';
import _ from 'lodash';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';

import BulkAssignButton from './components/BulkAssignButton';
import TabWindow from '../components/TabWindow';
import TaskTable, { docketNumberColumn, hearingBadgeColumn, detailsColumn,
  taskColumn, regionalOfficeColumn, issueCountColumn, typeColumn,
  assignedToColumn, daysWaitingColumn, readerLinkColumn } from './components/TaskTable';
import QueueOrganizationDropdown from './components/QueueOrganizationDropdown';
import Alert from '../components/Alert';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import {
  getUnassignedOrganizationalTasks,
  getAssignedOrganizationalTasks,
  getCompletedOrganizationalTasks,
  trackingTasksForOrganization
} from './selectors';
import { clearCaseSelectSearch } from '../reader/CaseSelect/CaseSelectActions';
import { fullWidth } from './constants';
import QUEUE_CONFIG from '../../constants/QUEUE_CONFIG.json';

const containerStyles = css({
  position: 'relative'
});

const alertStyling = css({
  marginBottom: '1.5em'
});

class OrganizationQueue extends React.PureComponent {
  componentDidMount = () => {
    this.props.clearCaseSelectSearch();
  }

  // To load the contents of the page:
  // tasks = request to /tasks?tab={config.name}
  calculateActiveTabIndex = (config) => {
    const tabNames = config.tabs.map((tab) => {
      return tab.name;
    });
    const index = _.indexOf(tabNames, config.active_tab);

    return index === -1 ? 0 : index;
  }

  queueConfig = () => {
    const config = this.props.queueConfig;

    config.active_tab_index = this.calculateActiveTabIndex(config);

    return config;
  }

  createColumnObject = (column, config) => {
    const functionForColumn = {
      hearingBadgeColumn: hearingBadgeColumn(config.tasks),
      detailsColumn: detailsColumn(config.tasks, false, config.userRole),
      taskColumn: taskColumn(config.tasks),
      regionalOfficeColumn: regionalOfficeColumn(config.tasks),
      typeColumn: typeColumn(config.tasks, false),
      assignedToColumn: assignedToColumn(config.tasks),
      docketNumberColumn: docketNumberColumn(config.tasks, false),
      daysWaitingColumn: daysWaitingColumn(false),
      readerLinkColumn: readerLinkColumn(false, true),
      issueCountColumn: issueCountColumn(false)
    };

    return functionForColumn[column];
  }

  columnsFromConfig = (tabConfig) => {
    return tabConfig.columns.map((column) => {
      return this.createColumnObject(column, tabConfig);
    });
  }

  tasksForTab = (tabName) => {
    const mapper = {
      [QUEUE_CONFIG.UNASSIGNED_TASKS_TAB_NAME]: this.props.unassignedTasks,
      [QUEUE_CONFIG.ASSIGNED_TASKS_TAB_NAME]: this.props.assignedTasks,
      [QUEUE_CONFIG.COMPLETED_TASKS_TAB_NAME]: this.props.completedTasks,
      [QUEUE_CONFIG.TRACKING_TASKS_TAB_NAME]: this.props.trackingTasks
    };

    return mapper[tabName];
  }

  taskTableTabFactory = (tabConfig) => {
    const { label, description } = tabConfig;
    const cols = this.columnsFromConfig(tabConfig);
    const tasks = this.tasksForTab(tabConfig.name);

    return {
      label,
      page: <React.Fragment>
        <p className="cf-margin-top-0">{description}</p>
        { tabConfig.allow_bulk_assign && <BulkAssignButton /> }
        <TaskTable
          customColumns={cols}
          tasks={tasks}
        />
      </React.Fragment>
    };
  }

  tabsFromConfig = (config) => {
    return config.tabs.map((tabConfig) => {
      return this.taskTableTabFactory(tabConfig, config);
    });
  }

  makeQueueComponents = (config) => {
    return <div>
      <h1 {...fullWidth}>{config.table_title}</h1>
      <QueueOrganizationDropdown organizations={this.props.organizations} />

      <TabWindow
        name="tasks-organization-queue"
        tabs={this.tabsFromConfig(config)}
        defaultPage={config.active_tab_index}
      />
    </div>;
  }

  render = () => {
    const { success, tasksAssignedByBulk } = this.props;
    const body = this.makeQueueComponents(this.queueConfig());

    return <AppSegment filledBackground styling={containerStyles}>
      {success && <Alert type="success" title={success.title} message={success.detail} />}
      {tasksAssignedByBulk.assignedUser &&
        <Alert
          message="Please go to your individual queue to see your self assigned tasks"
          title={`You have bulk assigned
            ${tasksAssignedByBulk.numberOfTasks}
            ${tasksAssignedByBulk.taskType.replace(/([a-z])([A-Z])/g, '$1 $2')}
            task(s)`}
          type="success"
          styling={alertStyling} />
      }
      {body}
    </AppSegment>;
  };
}

const mapStateToProps = (state) => {
  const { success } = state.ui.messages;

  return {
    success,
    userRole: state.ui.userRole,
    organizationName: state.ui.activeOrganization.name,
    organizationIsVso: state.ui.activeOrganization.isVso,
    organizations: state.ui.organizations,
    tasksAssignedByBulk: state.queue.tasksAssignedByBulk,
    unassignedTasks: getUnassignedOrganizationalTasks(state),
    assignedTasks: getAssignedOrganizationalTasks(state),
    completedTasks: getCompletedOrganizationalTasks(state),
    trackingTasks: trackingTasksForOrganization(state),
    queueConfig: state.queue.queueConfig
  };
};

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    clearCaseSelectSearch
  }, dispatch)
});

export default connect(mapStateToProps, mapDispatchToProps)(OrganizationQueue);
