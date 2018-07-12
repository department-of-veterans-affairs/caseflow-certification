// @flow
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import {
  resetErrorMessages,
  showErrorMessage,
  showSuccessMessage,
  resetSuccessMessages,
  setSelectedAssignee
} from '../uiReducer/uiActions';
import {
  initialAssignTasksToUser
} from '../QueueActions';
import SearchableDropdown from '../../components/SearchableDropdown';
import Button from '../../components/Button';
import _ from 'lodash';
import type {
  IsTaskAssignedToUserSelected, Tasks, UiStateError, State, AllAttorneys, UserWithId
} from '../types';
import Alert from '../../components/Alert';
import pluralize from 'pluralize';
import { ASSIGN_WIDGET_OTHER } from '../../../COPY.json';
import SmallLoader from '../../components/SmallLoader';
import { LOGO_COLORS } from '../../constants/AppConstants';

const OTHER = 'OTHER';

type Props = {|
  // Parameters
  previousAssigneeId: string,
  onTaskAssignment: Function,
  // From state
  selectedAssignee: string,
  isTaskAssignedToUserSelected: IsTaskAssignedToUserSelected,
  tasks: Tasks,
  error: ?UiStateError,
  success: string,
  allAttorneys: AllAttorneys,
  judges: UserWithId,
  loadedUserId: number,
  // Action creators
  setSelectedAssignee: Function,
  initialAssignTasksToUser: Function,
  showErrorMessage: (UiStateError) => void,
  resetErrorMessages: Function,
  showSuccessMessage: (string) => void,
  resetSuccessMessages: Function
|};

class AssignWidget extends React.PureComponent<Props> {
  selectedTasks = () => {
    return _.flatMap(
      this.props.isTaskAssignedToUserSelected[this.props.previousAssigneeId] || {},
      (selected, id) => (selected ? [this.props.tasks[id]] : []));
  }

  handleButtonClick = () => {
    const { previousAssigneeId, selectedAssignee } = this.props;
    const selectedTasks = this.selectedTasks();

    this.props.resetSuccessMessages();
    this.props.resetErrorMessages();

    if (!selectedAssignee) {
      this.props.showErrorMessage(
        { title: 'No assignee selected',
          detail: 'Please select someone to assign the tasks to.' });

      return;
    }

    if (selectedTasks.length === 0) {
      this.props.showErrorMessage(
        { title: 'No tasks selected',
          detail: 'Please select a task.' });

      return;
    }

    this.props.onTaskAssignment(
      { tasks: selectedTasks,
        assigneeId: selectedAssignee,
        previousAssigneeId }).
      then(() => this.props.showSuccessMessage(
        `Assigned ${selectedTasks.length} ${pluralize('case', selectedTasks.length)}`)).
      catch(() => this.props.showErrorMessage(
        { title: 'Error assigning tasks',
          detail: 'One or more tasks couldn\'t be assigned.' }));
  }

  fullNameOfJudgeWithCssId = (judgeCssId) => {
    const judge = _.find(this.props.judges, (judge) => judge && judge.css_id === judgeCssId);

    if (!judge) {
      return undefined;
    }

    return judge.full_name;
  }

  optionsFromJudgeAndAttorneys = (judgeCssId, attorneysOfJudgeWithCssId) => {
    if (!attorneysOfJudgeWithCssId[judgeCssId]) {
      return [];
    }

    const options = [];

    options.push({
      label: `${this.fullNameOfJudgeWithCssId(judgeCssId) || 'Other'}:`,
      value: judgeCssId,
      disabled: true
    });
    options.push(...attorneysOfJudgeWithCssId[judgeCssId].map((attorney) => ({ label: attorney.full_name,
      value: attorney.id.toString() })));

    return options;
  }

  render = () => {
    const { selectedAssignee, error, success, allAttorneys, judges, loadedUserId } = this.props;
    const userCssId = judges[loadedUserId];

    if (!allAttorneys.data && !allAttorneys.error) {
      return <SmallLoader message="Loading..." spinnerColor={LOGO_COLORS.QUEUE.ACCENT} />;
    }
    if (allAttorneys.error) {
      return <Alert type="error" title="Error fetching attorneys" message="Please refresh the page." />;
    }
    const handleChange = (option) => this.props.setSelectedAssignee({ assigneeId: option.value });
    const attorneys = allAttorneys.data;

    const options = [];

    {
      const attorneysOfJudgeWithCssId = _.groupBy(attorneys, (attorney) => attorney.judge_css_id);
      const judgeCssIds =
        [userCssId].concat(Object.keys(attorneysOfJudgeWithCssId).filter((cssId) => cssId !== userCssId));

      for (const judgeCssId of judgeCssIds) {
        options.push(...this.optionsFromJudgeAndAttorneys(judgeCssId, attorneysOfJudgeWithCssId));
      }
      options.push({ label: ASSIGN_WIDGET_OTHER,
        value: OTHER });
    }

    const selectedOption = _.find(options, (option) => option.value === selectedAssignee);

    return <React.Fragment>
      {error && <Alert type="error" title={error.title} message={error.detail} />}
      {success && <Alert type="success" title={success} />}
      <div {...css({
        display: 'flex',
        alignItems: 'center',
        flexWrap: 'wrap',
        '& > *': { marginRight: '1rem' } })}>
        <p>Assign to:&nbsp;</p>
        <SearchableDropdown
          name="Assignee"
          hideLabel
          searchable
          options={options}
          placeholder="Select a user"
          onChange={handleChange}
          value={selectedOption}
          styling={css({ width: '30rem' })} />
        <Button
          onClick={this.handleButtonClick}
          name={`Assign ${this.selectedTasks().length} ${pluralize('case', this.selectedTasks().length)}`}
          loading={false}
          loadingText="Loading" />
      </div>
    </React.Fragment>;
  }
}

const mapStateToProps = (state: State) => {
  const { isTaskAssignedToUserSelected, tasks, allAttorneys, judges, loadedQueue: { loadedUserId } } = state.queue;
  const { selectedAssignee, messages: { error, success } } = state.ui;

  return {
    selectedAssignee,
    isTaskAssignedToUserSelected,
    tasks,
    error,
    success,
    allAttorneys,
    judges,
    loadedUserId
  };
};

export default connect(
  mapStateToProps,
  (dispatch) => bindActionCreators({
    setSelectedAssignee,
    initialAssignTasksToUser,
    showErrorMessage,
    resetErrorMessages,
    showSuccessMessage,
    resetSuccessMessages
  }, dispatch)
)(AssignWidget);
