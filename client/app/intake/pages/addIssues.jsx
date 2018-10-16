import _ from 'lodash';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { Redirect } from 'react-router-dom';
import React from 'react';

import AddIssuesModal from '../components/AddIssuesModal';
import NonRatedIssueModal from '../components/NonRatedIssueModal';
import RemoveIssueModal from '../components/RemoveIssueModal';
import UnidentifiedIssuesModal from '../components/UnidentifiedIssuesModal';
import Button from '../../components/Button';
import RequestIssuesUpdateErrorAlert from '../../intakeEdit/components/RequestIssuesUpdateErrorAlert';
import { REQUEST_STATE, FORM_TYPES, PAGE_PATHS } from '../constants';
import REQUEST_ISSUES from '../../../constants/REQUEST_ISSUES.json';
import { formatDate } from '../../util/DateUtil';
import { formatAddedIssues, getAddIssuesFields } from '../util/issues';
import Table from '../../components/Table';
import {
  toggleAddIssuesModal,
  toggleNonRatedIssueModal,
  removeIssue,
  toggleUnidentifiedIssuesModal,
  toggleIssueRemoveModal
} from '../actions/addIssues';

export class AddIssuesPage extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      issueRemoveIndex: 0
    };
  }

  onRemoveClick = (index) => {
    if (this.props.toggleIssueRemoveModal) {
      // on the edit page, so show the remove modal
      this.setState({
        issueRemoveIndex: index
      });
      this.props.toggleIssueRemoveModal();
    } else {
      this.props.removeIssue(index);
    }
  }

  render() {
    const {
      intakeForms,
      formType,
      veteran,
      responseErrorCode,
      requestState
    } = this.props;

    if (!formType) {
      return <Redirect to={PAGE_PATHS.BEGIN} />;
    }

    const selectedForm = _.find(FORM_TYPES, { key: formType });
    const intakeData = intakeForms[selectedForm.key];
    const veteranInfo = `${veteran.name} (${veteran.fileNumber})`;

    const issuesComponent = () => {
      let issues = formatAddedIssues(intakeData);

      return <div className="issues">
        <div>
          { issues.map((issue, index) => {
            let issueKlasses = ['issue-desc'];
            let addendum = '';

            if (issue.isUnidentified) {
              issueKlasses.push('unidentified-issue');
            }
            if (issue.inActiveReview) {
              issueKlasses.push('in-active-review');
              addendum = REQUEST_ISSUES.ineligible_in_active_review_msg.replace('{review_title}', issue.inActiveReview);
            }

            return <div className="issue" key={`issue-${index}`}>
              <div className={issueKlasses.join(' ')}>
                <span className="issue-num">{index + 1}.&nbsp;</span>
                {issue.text} {addendum}
                { issue.date && <span className="issue-date">Decision date: {issue.date}</span> }
                { issue.notes && <span className="issue-notes">Notes:&nbsp;{issue.notes}</span> }
              </div>
              <div className="issue-action">
                <Button
                  onClick={() => this.onRemoveClick(index)}
                  classNames={['cf-btn-link', 'remove-issue']}
                >
                  <i className="fa fa-trash-o" aria-hidden="true"></i>Remove
                </Button>
              </div>
            </div>;
          })}
        </div>
        <div className="cf-actions">
          <Button
            name="add-issue"
            legacyStyling={false}
            classNames={['usa-button-secondary']}
            onClick={this.props.toggleAddIssuesModal}
          >
            + Add issue
          </Button>
        </div>
      </div>;
    };

    const columns = [
      { valueName: 'field' },
      { valueName: 'content' }
    ];

    let sharedFields = [
      { field: 'Form',
        content: selectedForm.name },
      { field: 'Veteran',
        content: veteranInfo },
      { field: 'Receipt date of this form',
        content: formatDate(intakeData.receiptDate) }
    ];

    let additionalFields = getAddIssuesFields(selectedForm.key, veteran, intakeData);
    let rowObjects = sharedFields.concat(additionalFields).concat(
      { field: 'Requested issues',
        content: issuesComponent() }
    );

    return <div className="cf-intake-edit">
      { intakeData.addIssuesModalVisible && <AddIssuesModal
        intakeData={intakeData}
        closeHandler={this.props.toggleAddIssuesModal} />
      }
      { intakeData.nonRatedIssueModalVisible && <NonRatedIssueModal
        intakeData={intakeData}
        closeHandler={this.props.toggleNonRatedIssueModal} />
      }
      { intakeData.unidentifiedIssuesModalVisible && <UnidentifiedIssuesModal
        intakeData={intakeData}
        closeHandler={this.props.toggleUnidentifiedIssuesModal} />
      }
      { intakeData.removeIssueModalVisible && <RemoveIssueModal
        removeIndex={this.state.issueRemoveIndex}
        intakeData={intakeData}
        closeHandler={this.props.toggleIssueRemoveModal} />
      }
      <h1 className="cf-txt-c">Add / Remove Issues</h1>

      { requestState === REQUEST_STATE.FAILED &&
        <RequestIssuesUpdateErrorAlert responseErrorCode={responseErrorCode} />
      }

      <Table
        columns={columns}
        rowObjects={rowObjects}
        slowReRendersAreOk />
    </div>;
  }
}

export const IntakeAddIssuesPage = connect(
  ({ intake, higherLevelReview, supplementalClaim, appeal }) => ({
    intakeForms: {
      higher_level_review: higherLevelReview,
      supplemental_claim: supplementalClaim,
      appeal
    },
    formType: intake.formType,
    veteran: intake.veteran,
    requestState: null,
    responseErrorCode: null
  }),
  (dispatch) => bindActionCreators({
    toggleAddIssuesModal,
    toggleNonRatedIssueModal,
    toggleUnidentifiedIssuesModal,
    removeIssue
  }, dispatch)
)(AddIssuesPage);

export const EditAddIssuesPage = connect(
  (state) => ({
    intakeForms: {
      higher_level_review: state,
      supplemental_claim: state
    },
    formType: state.formType,
    veteran: state.veteran,
    requestState: state.requestStatus.requestIssuesUpdate,
    responseErrorCode: state.responseErrorCode
  }),
  (dispatch) => bindActionCreators({
    toggleAddIssuesModal,
    toggleIssueRemoveModal,
    toggleNonRatedIssueModal,
    toggleUnidentifiedIssuesModal,
    removeIssue
  }, dispatch)
)(AddIssuesPage);
