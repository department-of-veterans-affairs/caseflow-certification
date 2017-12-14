import React from 'react';
import Button from '../../components/Button';
import BareOrderedList from '../../components/BareOrderedList';
import CancelButton from '../components/CancelButton';
import Checkbox from '../../components/Checkbox';
import Alert from '../../components/Alert';
import Table from '../../components/Table';
import { Redirect } from 'react-router-dom';
import { REQUEST_STATE, PAGE_PATHS, RAMP_INTAKE_STATES } from '../constants';
import { connect } from 'react-redux';
import { completeIntake, confirmFinishIntake } from '../actions/rampElection';
import { bindActionCreators } from 'redux';
import { getRampElectionStatus } from '../helpers/rampElection';
import _ from 'lodash';

const submitText = 'Finish intake';

class Finish extends React.PureComponent {
  getIssuesAlertContent = (appeals) => {
    const issueColumns = [
      {
        header: 'Program',
        valueName: 'programDescription'
      },
      {
        header: 'VACOLS Issue(s)',
        valueFunction: (issue, index) => (
          issue.description.map(
            (descriptor) => <div key={`${descriptor}-${index}`}>{descriptor}</div>
          )
        )
      },
      {
        header: 'Note',
        valueName: 'note'
      }
    ];

    return _.map(appeals, (appeal) => (
      <Table
        key={appeal.id}
        columns={issueColumns}
        rowObjects={appeal.issues}
        slowReRendersAreOk
        summary="Appeal issues"
      />
    ));
  }

  render() {
    const { rampElection, appeals, requestState } = this.props;

    switch (getRampElectionStatus(rampElection)) {
    case RAMP_INTAKE_STATES.NONE:
      return <Redirect to={PAGE_PATHS.BEGIN} />;
    case RAMP_INTAKE_STATES.STARTED:
      return <Redirect to={PAGE_PATHS.REVIEW} />;
    case RAMP_INTAKE_STATES.COMPLETED:
      return <Redirect to={PAGE_PATHS.COMPLETED} />;
    default:
    }

    let optionName;

    if (this.props.rampElection.optionSelected === 'supplemental_claim') {
      optionName = 'Supplemental Claim';
    } else {
      optionName = 'Higher-Level Review';
    }

    const steps = [
      <span>
        Upload the RAMP Election form to the VBMS eFolder and ensure the
        Document Type is <b>Correspondence</b>.
      </span>,
      <span>Update the Subject Line with "Ramp Election".</span>
    ];
    const stepFns = steps.map((step, index) =>
      () => <span><strong>Step {index + 1}.</strong> {step}</span>
    );

    const issuesAlertTitle = `This Veteran has ${appeals.length} ` +
                             `eligible ${appeals.length === 1 ? 'appeal' : 'appeals'}` +
                             ', with the following issues';

    return <div>
      <h1>Finish processing { optionName } election</h1>

      { requestState === REQUEST_STATE.FAILED &&
        <Alert title="Something went wrong" type="error" lowerMargin>
          Please try again. If the problem persists, please contact Caseflow support.
        </Alert>
      }

      <p>Please complete the following steps outside Caseflow.</p>
      <BareOrderedList className="cf-steps-outside-of-caseflow-list" items={stepFns} />

      <Alert title={issuesAlertTitle} type="info">
        { this.getIssuesAlertContent(appeals) }
      </Alert>

      <Checkbox
        label="I've completed the above steps outside Caseflow."
        name="confirm-finish"
        required
        value={rampElection.finishConfirmed}
        onChange={this.props.confirmFinishIntake}
        errorMessage={rampElection.finishConfirmedError}
      />
    </div>;
  }
}

class FinishNextButton extends React.PureComponent {
  handleClick = () => {
    this.props.completeIntake(this.props.intakeId, this.props.rampElection).then(
      (completeWasSuccessful) => {
        if (completeWasSuccessful) {
          this.props.history.push('/completed');
        }
      }
    );
  }

  render = () =>
    <Button
      name="submit-review"
      onClick={this.handleClick}
      loading={this.props.requestState === REQUEST_STATE.IN_PROGRESS}
      legacyStyling={false}
    >
      { submitText }
    </Button>;
}

const FinishNextButtonConnected = connect(
  ({ rampElection, intake }) => ({
    requestState: rampElection.requestStatus.completeIntake,
    intakeId: intake.id,
    rampElection
  }),
  (dispatch) => bindActionCreators({
    completeIntake
  }, dispatch)
)(FinishNextButton);

export class FinishButtons extends React.PureComponent {
  render = () =>
    <div>
      <CancelButton />
      <FinishNextButtonConnected history={this.props.history} />
    </div>
}

export default connect(
  ({ rampElection }) => ({
    rampElection,
    appeals: rampElection.appeals,
    requestState: rampElection.requestStatus.completeIntake
  }),
  (dispatch) => bindActionCreators({
    confirmFinishIntake
  }, dispatch)
)(Finish);
