// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import StatusMessage from '../components/StatusMessage';
import JudgeAssignTaskTable from './JudgeAssignTaskTable';
import SmallLoader from '../components/SmallLoader';
import { LOGO_COLORS } from '../constants/AppConstants';
import { reassignTasksToUser } from './QueueActions';
import { sortTasks } from './utils';
import { selectedTasksSelector } from './selectors';
import AssignWidget from './components/AssignWidget';
import {
  resetErrorMessages,
  resetSuccessMessages
} from './uiReducer/uiActions';
import Alert from '../components/Alert';
import type { Task, Tasks } from './types/models';
import type { AttorneysOfJudge, TasksAndAppealsOfAttorney, UiStateError, State } from './types/state';

type Params = {|
  match: Object
|};

type Props = Params & {|
  // From state
  attorneysOfJudge: AttorneysOfJudge,
  featureToggles: Object,
  selectedTasks: Array<Task>,
  tasks: Tasks,
  tasksAndAppealsOfAttorney: TasksAndAppealsOfAttorney,
  success: string,
  error: ?UiStateError,
  // Action creators
  resetSuccessMessages: typeof resetSuccessMessages,
  resetErrorMessages: typeof resetErrorMessages,
  reassignTasksToUser: typeof reassignTasksToUser
|};

class AssignedCasesPage extends React.PureComponent<Props> {
  componentDidMount = () => {
    this.props.resetSuccessMessages();
    this.props.resetErrorMessages();
  }

  componentDidUpdate = (prevProps) => {
    const { attorneyId: prevAttorneyId } = prevProps.match.params;
    const { attorneyId } = this.props.match.params;

    if (attorneyId !== prevAttorneyId) {
      this.props.resetSuccessMessages();
      this.props.resetErrorMessages();
    }
  }

  render = () => {
    const props = this.props;
    const {
      match, attorneysOfJudge, tasksAndAppealsOfAttorney, tasks, featureToggles, selectedTasks, success, error
    } = props;
    const { attorneyId } = match.params;

    if (!(attorneyId in tasksAndAppealsOfAttorney) || tasksAndAppealsOfAttorney[attorneyId].state === 'LOADING') {
      return <SmallLoader message="Loading..." spinnerColor={LOGO_COLORS.QUEUE.ACCENT} />;
    }

    if (tasksAndAppealsOfAttorney[attorneyId].state === 'FAILED') {
      const { error: loadingError } = tasksAndAppealsOfAttorney[attorneyId];

      if (!loadingError.response) {
        return <StatusMessage title="Timeout">Error fetching cases</StatusMessage>;
      }

      return <StatusMessage title={loadingError.response.statusText}>Error fetching cases</StatusMessage>;
    }

    const attorneyName = attorneysOfJudge.filter((attorney) => attorney.id.toString() === attorneyId)[0].full_name;
    const { tasks: taskIdsOfAttorney, appeals } = tasksAndAppealsOfAttorney[attorneyId].data;
    const tasksOfAttorney = {};

    for (const taskId of Object.keys(taskIdsOfAttorney)) {
      tasksOfAttorney[taskId] = tasks[taskId];
    }

    return <React.Fragment>
      <h2>{attorneyName}'s Cases</h2>
      {error && <Alert type="error" title={error.title} message={error.detail} scrollOnAlert={false} />}
      {success && <Alert type="success" title={success} scrollOnAlert={false} />}
      {featureToggles.judge_assignment_to_attorney &&
        <AssignWidget
          previousAssigneeId={attorneyId}
          onTaskAssignment={(params) => props.reassignTasksToUser(params)}
          selectedTasks={selectedTasks} />}
      <JudgeAssignTaskTable
        tasksAndAppeals={
          sortTasks({
            tasks: tasksOfAttorney,
            appeals
          }).
            map((task) => ({
              task,
              appeal: appeals[task.appealId] }))
        }
        userId={attorneyId} />
    </React.Fragment>;
  }
}

const mapStateToProps = (state: State, ownProps: Params) => {
  const { tasksAndAppealsOfAttorney, attorneysOfJudge, tasks } = state.queue;
  const {
    featureToggles,
    messages: {
      success,
      error
    }
  } = state.ui;
  const { attorneyId } = ownProps.match.params;

  return {
    tasksAndAppealsOfAttorney,
    attorneysOfJudge,
    tasks,
    featureToggles,
    selectedTasks: selectedTasksSelector(state, attorneyId),
    success,
    error
  };
};

export default (connect(
  mapStateToProps,
  (dispatch) => (bindActionCreators({
    reassignTasksToUser,
    resetErrorMessages,
    resetSuccessMessages
  }, dispatch)))(AssignedCasesPage): React.ComponentType<Params>);
