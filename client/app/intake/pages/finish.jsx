import React from 'react';
import Button from '../../components/Button';
import BareOrderedList from '../../components/BareOrderedList';
import CancelButton from '../components/CancelButton';
import Checkbox from '../../components/Checkbox';
import { Redirect } from 'react-router-dom';
import { REQUEST_STATE, PAGE_PATHS, RAMP_INTAKE_STATES } from '../constants';
import { connect } from 'react-redux';
import { completeIntake, confirmFinishIntake } from '../redux/actions';
import { bindActionCreators } from 'redux';
import { getRampElectionStatus } from '../redux/selectors';

const submitText = "I've completed all steps";

class Finish extends React.PureComponent {
  render() {
    const { rampElection } = this.props;

    switch (this.props.rampElectionStatus) {
    case RAMP_INTAKE_STATES.NONE:
      return <Redirect to={PAGE_PATHS.BEGIN}/>;
    case RAMP_INTAKE_STATES.STARTED:
      return <Redirect to={PAGE_PATHS.REVIEW}/>;
    case RAMP_INTAKE_STATES.COMPLETED:
      return <Redirect to={PAGE_PATHS.COMPLETED}/>;
    default:
    }

    const steps = [
      <span>Upload the RAMP election form to VBMS and ensure the Document Type is <em>Correspondence</em>.</span>,
      <span>Update the Subject Line with <em>RAMP Opt-In</em>.</span>,
      <span>Create an EP <strong>030 RAMP Supplemental</strong> in VBMS.</span>,
      <span>Add a placeholder contention of <em>RAMP</em>.</span>
    ];
    const stepFns = steps.map((step, index) => () => <span><strong>Step {index}.</strong> {step}</span>);

    return <div>
      <h1>Finish processing Supplemental Claim request</h1>
      <p>Please complete the following 4 steps outside Caseflow.</p>
      <BareOrderedList className="cf-steps-outside-of-caseflow-list" items={stepFns} />
      <Checkbox
        label={
          <span>
            I confirm that I have completed all of the steps above.
            I understand that selecting the
            <b> { submitText } </b>
            button below will close the VACOLS record.
          </span>
        }
        name="confirm-finish"
        required={true}
        value={rampElection.finishConfirmed}
        onChange={this.props.confirmFinishIntake}
        errorMessage={rampElection.finishConfirmedError}
      />
    </div>;
  }
}

class FinishNextButton extends React.PureComponent {
  handleClick = () => {
    this.props.completeIntake(this.props.rampElection).then(
      () => this.props.history.push('/completed')
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
  ({ rampElection, requestStatus }) => ({
    requestState: requestStatus.completeIntake,
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
  (state) => ({
    rampElection: state.rampElection,
    rampElectionStatus: getRampElectionStatus(state)
  }),
  (dispatch) => bindActionCreators({
    confirmFinishIntake
  }, dispatch)
)(Finish);
