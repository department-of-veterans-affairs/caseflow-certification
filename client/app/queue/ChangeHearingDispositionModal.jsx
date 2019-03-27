import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';
import { sprintf } from 'sprintf-js';
import _ from 'lodash';
import moment from 'moment';

import COPY from '../../COPY.json';
import HEARING_DISPOSITION_TYPES from '../../constants/HEARING_DISPOSITION_TYPES.json';

import {
  taskById,
  appealWithDetailSelector
} from './selectors';

import { onReceiveAmaTasks } from './QueueActions';

import SearchableDropdown from '../components/SearchableDropdown';
import TextareaField from '../components/TextareaField';
import QueueFlowModal from './components/QueueFlowModal';

import {
  requestPatch,
  requestSave
} from './uiReducer/uiActions';

import { taskActionData } from './utils';

const selectedAction = (props) => {
  const actionData = taskActionData(props);

  return actionData.selected ? actionData.options.find((option) => option.value === actionData.selected.id) : null;
};

class ChangeHearingDispositionModal extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      selectedValue: null,
      instructions: ''
    };
  }
  submit = () => {
    console.log("submit!");
  }

  validateForm = () => {
    return this.state.selectedValue !== null && this.state.instructions !== '';
  }

  render = () => {
    const {
      appeal,
      highlightFormItems,
      task
    } = this.props;
    //
    // const action = this.props.task && this.props.task.availableActions.length > 0 ? selectedAction(this.props) : null;
    // const actionData = taskActionData(this.props);
    //
    // if (!task || task.availableActions.length === 0) {
    //   return null;
    // }

    const hearing = _.find(appeal.hearings, { externalId: task.externalHearingId });
    const currentDisposition = hearing.disposition ? _.startCase(hearing.disposition) : 'None';
    const dispositionOptions = Object.keys(HEARING_DISPOSITION_TYPES).map((key) =>
      ({
        value: key,
        label: _.startCase(key)
      })
    );

    // debugger;
    return <QueueFlowModal
      title="Change hearing disposition"
      pathAfterSubmit = "/queue"
      submit={this.submit}
      validateForm={this.validateForm}
    >
      <p>Changing the hearing disposition for this case will close all the
        open tasks and will remove the case from the current workflow.</p>

      <p><strong>Hearing Date:</strong> {moment(hearing.date).format('MM/DD/YYYY')}</p>
      <p><strong>Current Disposition:</strong> {currentDisposition}</p>

      <SearchableDropdown
        name="New Disposition"
        errorMessage={highlightFormItems && !this.state.selectedValue ? 'Choose one' : null}
        placeholder="Select"
        value={this.state.selectedValue}
        onChange={(option) => this.setState({ selectedValue: option ? option.value : null })}
        options={dispositionOptions} />
      <br />
      <TextareaField
        name="Notes"
        errorMessage={highlightFormItems && !this.state.instructions ? COPY.FORM_ERROR_FIELD_REQUIRED : null}
        id="taskInstructions"
        onChange={(value) => this.setState({ instructions: value })}
        value={this.state.instructions} />

    </QueueFlowModal>;
  }
}

const mapStateToProps = (state, ownProps) => {
  const {
    highlightFormItems
  } = state.ui;

  return {
    highlightFormItems,
    task: taskById(state, { taskId: ownProps.taskId }),
    appeal: appealWithDetailSelector(state, ownProps)
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestPatch,
  requestSave,
  onReceiveAmaTasks
}, dispatch);

export default (withRouter(connect(mapStateToProps, mapDispatchToProps)(ChangeHearingDispositionModal)));
