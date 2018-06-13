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
import {
  setAttorneysOfJudge, fetchTasksAndAppealsOfAttorney, setSelectionOfTaskOfUser, setSelectedAssigneeOfUser,
  initialAssignTasksToUser
} from './QueueActions';
import { sortTasks } from './utils';
import PageRoute from '../components/PageRoute';
import AssignedCasesPage from './AssignedCasesPage';
import SearchableDropdown from '../components/SearchableDropdown';
import Button from '../components/Button';

class AssignWidgetPresentational extends React.PureComponent {
  constructor(props) {
    super(props);
    this.state = { statusMessage: null };
  }

  idsOfSelectedTasks = () => {
    return _.flatMap(
      this.props.isTaskAssignedToUserSelected[this.props.userId] || [],
      (selected, taskId) => (selected ? [taskId] : []));
  }

  handleButtonClick = () => {
    const { userId, selectedAssigneeOfUser, initialAssignTasksToUser } = this.props;

    if (!selectedAssigneeOfUser[userId]) {
      this.setState({ statusMessage: <div className="usa-alert usa-alert-error" role="alert">
        <div className="usa-alert-body">
          <h3 className="usa-alert-heading">No assignee</h3>
          <p className="usa-alert-text">Please select someone to assign the tasks to.</p>
        </div>
      </div> });

      return;
    }

    if (this.idsOfSelectedTasks().length === 0) {
      this.setState({ statusMessage: <div className="usa-alert usa-alert-error" role="alert">
        <div className="usa-alert-body">
          <h3 className="usa-alert-heading">No tasks select</h3>
          <p className="usa-alert-text">Please select a task.</p>
        </div>
      </div> });

      return;
    }

    initialAssignTasksToUser(
      { idsOfTasks: this.idsOfSelectedTasks(),
        assigneeId: selectedAssigneeOfUser[userId] });
  }

  render = () => {
    const { userId, attorneysOfJudge, selectedAssigneeOfUser } = this.props;
    const options = attorneysOfJudge.map((attorney) => ({ label: attorney.full_name,
      value: attorney.id.toString() }));
    const selectedOption =
      selectedAssigneeOfUser[userId] ?
        options.filter((option) => option.value === selectedAssigneeOfUser[userId])[0] :
        { label: 'Select a user',
          value: null };

    return <React.Fragment>
      {this.state.statusMessage}
      <div style={{ display: 'flex',
        alignItems: 'center' }}>
        <p>Assign to:&nbsp;</p>
        <SearchableDropdown
          name="Assignee"
          hideLabel
          searchable
          options={options}
          onChange={(option) => this.props.setSelectedAssigneeOfUser({ userId,
            assigneeId: option.value })}
          value={selectedOption}
          dropdownStyling={{ width: '30rem' }} />
        <p>&nbsp;</p>
        <Button
          onClick={this.handleButtonClick}
          name={`Assign ${this.idsOfSelectedTasks().length} case(s)`}
          loading={false}
          loadingText="Loading" />
      </div>
    </React.Fragment>;
  }
}

const AssignWidget =
  connect(
    (state) => _.pick(state.queue, 'attorneysOfJudge', 'selectedAssigneeOfUser', 'isTaskAssignedToUserSelected'),
    (dispatch) => bindActionCreators({ setSelectedAssigneeOfUser,
      initialAssignTasksToUser }, dispatch)
  )(AssignWidgetPresentational);

const UnassignedCasesPage = (props) => {
  const { attorneys, tasksAndAppeals: { length: reviewableCount }, userId, featureToggles } = props;
  let tableContent;

  if (reviewableCount === 0) {
    tableContent = <StatusMessage title="Tasks not found">
       Congratulations! You don't have any cases to assign.
    </StatusMessage>;
  } else {
    tableContent = <React.Fragment>
      <h2>Cases to Assign</h2>
      {featureToggles.judge_assign_cases ? <AssignWidget userId={userId} /> : null}
      <JudgeAssignTaskTable {...props} />
    </React.Fragment>;
  }

  return tableContent;
};

class JudgeAssignTaskListView extends React.PureComponent {
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
                  Cases to Assign ({this.unassignedTasksWithAppeals().length})
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
            title="Cases to Assign | Caseflow"
            render={
              () => <UnassignedCasesPage
                tasksAndAppeals={this.unassignedTasksWithAppeals()}
                userId={this.props.userId.toString()}
                attorneys={attorneysOfJudge}
                featureToggles={this.props.featureToggles} />}
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

const mapStateToProps = (state) => {
  const {
    queue: {
      attorneysOfJudge,
      tasksAndAppealsOfAttorney,
      tasks,
      loadedQueue: {
        tasks: loadedQueueTasks,
        appeals
      }
    },
    ui: {
      featureToggles
    }
  } = state;

  return {
    attorneysOfJudge,
    tasksAndAppealsOfAttorney,
    tasks,
    loadedQueueTasks,
    appeals,
    featureToggles
  };
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
