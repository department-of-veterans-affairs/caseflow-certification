import React, { Component } from 'react';
import Button from '../components/Button';
import { Link } from 'react-router-dom';
import { formatDate } from '../util/DateUtil';
import Table from '../components/Table';

const summary = 'Claims for manager review';

const formatExplanation = (intake) => {
  const explanationCopy = {
    veteran_not_accessible: 'sensitivity',
    veteran_not_valid: 'missing profile information',
    no_eligible_appeals: 'no eligible appeals',
    no_active_fully_compensation_appeals: 'no compensation issues',
    duplicate_ep: 'Duplicate EP created outside Caseflow',
    system_error: 'System error',
    missing_signature: 'Missing signature',
    veteran_clarification: 'Need clarification from Veteran'
  }

  if (intake.completion_status === 'error') {
    return `Error: ${explanationCopy[intake.error_code]}`
  } else if (intake.completion_status === 'canceled'){
    const cancel_explanation = intake.cancel_other ? intake.cancel_other : explanationCopy[intake.cancel_reason]
    return `Canceled: ${cancel_explanation}`
  }
}

const columns = [
  {
    header: 'Veteran File Number',
    valueName: 'veteran_file_number'
  },
  {
    header: 'Date Processed',
    align: 'center',
    valueFunction: (intake) => formatDate(intake.completed_at)
  },
  {
    header: 'Form',
    valueFunction: (intake) => intake.type === 'RampElectionIntake' ? 'RAMP Opt-In Election Form' : '21-4138 RAMP Selection Form'
  },
  {
    header: 'Employee',
    valueName: 'full_name'
  },
  {
    header: 'Explanation',
    valueFunction: (intake) => cancelExplanation(intake)
  }
];

export default class IntakesForReview extends Component {
  render = () => {
    return <div className="cf-app-segment cf-app-segment--alt cf-manager-intakes">
      <div className='cf-manage-intakes-header'>
        <div>
          <h1>Claims for manager review</h1>
          <p>
          This list shows claims that did not result in an End Product (EP)
          because the user canceled midway through processing, or did not finish
          establishing the claim after receiving an alert message. After an EP is
          successfully established, you can <a href="" className="cf-action-refresh">refresh</a> the
          page to update this list.
          </p>
        </div>
        <div>
          <a href="/stats">
            <Button linkStyling>View stats</Button>
          </a>
          <a href="/intake">
            <Button legacyStyling={false} classNames={['usa-button-secondary']}>Begin intake</Button>
          </a>
        </div>
      </div>


      <Table
        columns={columns}
        rowObjects={this.props.intakes}
        summary={summary}
        slowReRendersAreOk />
    </div>;
  }
}
