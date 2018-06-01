// @flow
import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';

import StatusMessage from '../components/StatusMessage';
import AttorneyTaskTable from './AttorneyTaskTable';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Alert from '../components/Alert';

import {
  resetErrorMessages,
  resetSuccessMessages,
  resetSaveState,
  showErrorMessage
} from './uiReducer/uiActions';
import { clearCaseSelectSearch } from '../reader/CaseSelect/CaseSelectActions';

import { fullWidth } from './constants';
import COPY from '../../COPY.json';
import type { Tasks, LoadedQueueTasks, LoadedQueueAppeals } from './reducers';

class AttorneyTaskListView extends React.PureComponent<{loadedQueueTasks: LoadedQueueTasks, appeals: LoadedQueueAppeals, tasks: Tasks, messages: Object, showErrorMessage: Function, resetSaveState: Function, resetSuccessMessages: Function, resetErrorMessages: Function, clearCaseSelectSearch: Function}> {
  componentWillUnmount = () => {
    this.props.resetSaveState();
    this.props.resetSuccessMessages();
    this.props.resetErrorMessages();
  }

  componentDidMount = () => {
    this.props.clearCaseSelectSearch();
    this.props.resetErrorMessages();

    if (_.some(this.props.loadedQueueTasks, (task) => !this.props.tasks[task.id].attributes.task_id)) {
      this.props.showErrorMessage({
        title: COPY.TASKS_NEED_ASSIGNMENT_ERROR_TITLE,
        detail: COPY.TASKS_NEED_ASSIGNMENT_ERROR_MESSAGE
      });
    }
  };

  render = () => {
    const { messages } = this.props;
    const noTasks = !_.size(this.props.loadedQueueTasks) && !_.size(this.props.appeals);
    let tableContent;

    if (noTasks) {
      tableContent = <StatusMessage title={COPY.NO_TASKS_IN_ATTORNEY_QUEUE_TITLE}>
        {COPY.NO_TASKS_IN_ATTORNEY_QUEUE_MESSAGE}
      </StatusMessage>;
    } else {
      tableContent = <div>
        <h1 {...fullWidth}>{COPY.ATTORNEY_QUEUE_TABLE_TITLE}</h1>
        {messages.error && <Alert type="error" title={messages.error.title}>
          {messages.error.detail}
        </Alert>}
        {messages.success && <Alert type="success" title={messages.success}>
          {COPY.ATTORNEY_QUEUE_TABLE_SUCCESS_MESSAGE_DETAIL}
        </Alert>}
        <AttorneyTaskTable />
      </div>;
    }

    return <AppSegment filledBackground>
      {tableContent}
    </AppSegment>;
  };
}

AttorneyTaskListView.propTypes = {
  loadedQueueTasks: PropTypes.object.isRequired,
  appeals: PropTypes.object.isRequired
};

const mapStateToProps = (state) => ({
  ..._.pick(state.queue.loadedQueue, 'appeals'),
  ..._.pick(state.ui, 'messages'),
  ..._.pick(state.queue.stagedChanges, 'taskDecision'),
  ..._.pick(state.queue, 'tasks'),
  judges: state.queue.judges,
  loadedQueueTasks: state.queue.loadedQueue.tasks,
});

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    clearCaseSelectSearch,
    resetErrorMessages,
    resetSuccessMessages,
    resetSaveState,
    showErrorMessage
  }, dispatch)
});

export default connect(mapStateToProps, mapDispatchToProps)(AttorneyTaskListView);
