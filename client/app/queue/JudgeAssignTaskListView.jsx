// @flow
import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import StatusMessage from '../components/StatusMessage';
import JudgeAssignTaskTable from './JudgeAssignTaskTable';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import {
  resetErrorMessages,
  resetSuccessMessages,
  resetSaveState
} from './uiReducer/uiActions';
import { clearCaseSelectSearch } from '../reader/CaseSelect/CaseSelectActions';
import { fullWidth } from './constants';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import { NavLink } from 'react-router-dom';
import ApiUtil from '../util/ApiUtil';
import LoadingDataDisplay from '../components/LoadingDataDisplay';
import SmallLoader from '../components/SmallLoader';
import { LOGO_COLORS } from '../constants/AppConstants';
import { setAttorneysOfJudge, fetchTasksAndAppealsOfAttorney, setSelectionOfTaskOfUser } from './QueueActions';
import { sortTasks } from './utils';
import PageRoute from '../components/PageRoute';
import AssignedCasesPage from './AssignedCasesPage';
import type { State, LoadedQueueAppeals, LoadedQueueTasks, Tasks, TasksAndAppealsOfAttorney } from './reducers';

const UnassignedCasesPage = (props) => {
  const reviewableCount = props.tasksAndAppeals.length;
  let tableContent;

  if (reviewableCount === 0) {
    tableContent = <StatusMessage title="Tasks not found">
       Congratulations! You don't have any cases to assign.
    </StatusMessage>;
  } else {
    tableContent = <React.Fragment>
      <h2>Unassigned Cases</h2>
      <JudgeAssignTaskTable {...props} />
    </React.Fragment>;
  }

  return tableContent;
};

class JudgeAssignTaskListView extends React.PureComponent<{|
  attorneysOfJudge: Array<Object>,
  tasksAndAppealsOfAttorney: TasksAndAppealsOfAttorney,
  appeals: LoadedQueueAppeals,
  loadedQueueTasks: LoadedQueueTasks,
  tasks: Tasks,
  userId: string,
  userCssId: string,
  match: {params: {[string]: string}, url: string},
  clearCaseSelectSearch: Function,
  resetErrorMessages: Function,
  resetSuccessMessages: Function,
  resetSaveState: Function,
  setAttorneysOfJudge: Function,
  fetchTasksAndAppealsOfAttorney: Function,
  setSelectionOfTaskOfUser: Function
|}> {
  componentWillUnmount = () => {
    this.props.resetSaveState();
    this.props.resetSuccessMessages();
  }

  componentDidMount = () => {
    this.props.clearCaseSelectSearch();
    this.props.resetErrorMessages();
  };

  unassignedTasksWithAppeals = () => {
    const { loadedQueueTasks, appeals, tasks } = this.props;
    const taskWithId = {};

    for (const id of Object.keys(loadedQueueTasks)) {
      taskWithId[id] = tasks[id];
    }

    return sortTasks({ tasks: taskWithId,
      appeals }).
      filter((task) => task.attributes.task_type === 'Assign').
      map((task) => ({
        task,
        appeal: this.props.appeals[task.vacolsId] }));
  }

  switchLink = () => <Link to={`/queue/${this.props.userId}/review`}>Switch to Review Cases</Link>

  createLoadPromise = () => {
    const requestOptions = {
      timeout: true
    };

    return ApiUtil.get(`/users?role=Attorney&judge_css_id=${this.props.userCssId}`, requestOptions).
      then(
        (response) => {
          const resp = JSON.parse(response.text);

          this.props.setAttorneysOfJudge(resp.attorneys);
          for (const attorney of resp.attorneys) {
            this.props.fetchTasksAndAppealsOfAttorney(attorney.id);
          }
        });
  }

  caseCountOfAttorney = (attorneyId) => {
    const { tasksAndAppealsOfAttorney } = this.props;

    return attorneyId in tasksAndAppealsOfAttorney &&
        tasksAndAppealsOfAttorney[attorneyId].state === 'LOADED' ?
      Object.keys(tasksAndAppealsOfAttorney[attorneyId].data.tasks).length.toString() :
      '?';
  }

  render = () => {
    const { userId, attorneysOfJudge, match } = this.props;

    return <AppSegment filledBackground>
      <div>
        <div {...fullWidth} {...css({ marginBottom: '2em' })}>
          <h1>Assign {this.unassignedTasksWithAppeals().length} Cases</h1>
          {this.switchLink()}
        </div>
        <div className="usa-width-one-fourth">
          <LoadingDataDisplay
            createLoadPromise={this.createLoadPromise}
            errorComponent="span"
            failStatusMessageProps={{ title: 'Unknown failure' }}
            failStatusMessageChildren={<span>Failed to load sidebar</span>}
            loadingComponent={SmallLoader}
            loadingComponentProps={{
              message: 'Loading...',
              spinnerColor: LOGO_COLORS.QUEUE.ACCENT,
              component: 'span'
            }}>
            <ul className="usa-sidenav-list">
              <li>
                <NavLink to={`/queue/${userId}/assign`} activeClassName="usa-current" exact>
                  Unassigned Cases ({this.unassignedTasksWithAppeals().length})
                </NavLink>
              </li>
              {attorneysOfJudge.
                map((attorney) => <li key={attorney.id}>
                  <NavLink to={`/queue/${userId}/assign/${attorney.id}`} activeClassName="usa-current" exact>
                    {attorney.full_name} ({this.caseCountOfAttorney(attorney.id)})
                  </NavLink>
                </li>)}
            </ul>
          </LoadingDataDisplay>
        </div>
        <div className="usa-width-three-fourths">
          <PageRoute
            exact
            path={match.url}
            title="Unassigned Cases | Caseflow"
            render={
              () => <UnassignedCasesPage
                tasksAndAppeals={this.unassignedTasksWithAppeals()}
                userId={this.props.userId.toString()} />}
          />
          <PageRoute
            path={`${match.url}/:attorneyId`}
            title="Assigned Cases | Caseflow"
            component={AssignedCasesPage}
          />
        </div>
      </div>
    </AppSegment>;
  };
}

JudgeAssignTaskListView.propTypes = {
  loadedQueueTasks: PropTypes.object.isRequired,
  appeals: PropTypes.object.isRequired,
  attorneysOfJudge: PropTypes.array.isRequired,
  tasksAndAppealsOfAttorney: PropTypes.object.isRequired
};

const mapStateToProps = (state: State): {|
  attorneysOfJudge: Array<Object>,
  tasksAndAppealsOfAttorney: TasksAndAppealsOfAttorney,
  appeals: LoadedQueueAppeals,
  tasks: Tasks,
  loadedQueueTasks: LoadedQueueTasks
|} => {
  const {
    queue: {
      attorneysOfJudge,
      tasksAndAppealsOfAttorney,
      tasks,
      loadedQueue: {
        tasks: loadedQueueTasks,
        appeals
      }
    }
  } = state;

  return { attorneysOfJudge,
    tasksAndAppealsOfAttorney,
    tasks,
    loadedQueueTasks,
    appeals };
};

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    clearCaseSelectSearch,
    resetErrorMessages,
    resetSuccessMessages,
    resetSaveState,
    setAttorneysOfJudge,
    fetchTasksAndAppealsOfAttorney,
    setSelectionOfTaskOfUser
  }, dispatch)
);

export default connect(mapStateToProps, mapDispatchToProps)(JudgeAssignTaskListView);
