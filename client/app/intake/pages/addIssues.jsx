/* eslint-disable react/prop-types */

import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import _ from 'lodash';
import moment from 'moment';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { Redirect } from 'react-router-dom';

import RemoveIssueModal from '../components/RemoveIssueModal';
import CorrectionTypeModal from '../components/CorrectionTypeModal';
import AddIssueManager from '../components/AddIssueManager';

import Button from '../../components/Button';
import InlineForm from '../../components/InlineForm';
import DateSelector from '../../components/DateSelector';
import ErrorAlert from '../components/ErrorAlert';
import { REQUEST_STATE, PAGE_PATHS, VBMS_BENEFIT_TYPES, FORM_TYPES } from '../constants';
import EP_CLAIM_TYPES from '../../../constants/EP_CLAIM_TYPES';
import { formatAddedIssues, getAddIssuesFields } from '../util/issues';
import Table from '../../components/Table';
import IssueList from '../components/IssueList';

import {
  toggleAddingIssue,
  toggleAddIssuesModal,
  toggleUntimelyExemptionModal,
  toggleNonratingRequestIssueModal,
  removeIssue,
  withdrawIssue,
  setIssueWithdrawalDate,
  correctIssue,
  undoCorrection,
  toggleUnidentifiedIssuesModal,
  toggleIssueRemoveModal,
  toggleLegacyOptInModal,
  toggleCorrectionTypeModal
} from '../actions/addIssues';
import COPY from '../../../COPY';

class AddIssuesPage extends React.Component {
  constructor(props) {
    super(props);

    let originalIssueLength = 0;

    if (this.props.intakeForms && this.props.formType) {
      originalIssueLength = (this.props.intakeForms[this.props.formType].addedIssues || []).length;
    }

    this.state = {
      originalIssueLength,
      issueRemoveIndex: 0,
      issueIndex: 0,
      addingIssue: false
    };
  }

  onClickAddIssue = () => {
    this.setState({ addingIssue: true });
  };

  onClickIssueAction = (index, option = 'remove') => {
    switch (option) {
    case 'remove':
      if (this.props.toggleIssueRemoveModal) {
        // on the edit page, so show the remove modal
        this.setState({
          issueRemoveIndex: index
        });
        this.props.toggleIssueRemoveModal();
      } else {
        this.props.removeIssue(index);
      }
      break;
    case 'withdraw':
      this.props.withdrawIssue(index);
      break;
    case 'correct':
      this.props.toggleCorrectionTypeModal({ index });
      break;
    case 'undo_correction':
      this.props.undoCorrection(index);
      break;
    default:
      this.props.undoCorrection(index);
    }
  };

  withdrawalDateOnChange = (value) => {
    this.props.setIssueWithdrawalDate(value);
  };

  editingClaimReview() {
    const { formType, editPage } = this.props;

    return (formType === 'higher_level_review' || formType === 'supplemental_claim') && editPage;
  }

  willRedirect(intakeData, hasClearedEp) {
    const { formType, processedAt, featureToggles } = this.props;
    const { correctClaimReviews } = featureToggles;

    return (
      !formType ||
      (this.editingClaimReview() && !processedAt) ||
      intakeData.isOutcoded ||
      (hasClearedEp && !correctClaimReviews)
    );
  }

  redirect(intakeData, hasClearedEp) {
    const { formType, processedAt } = this.props;

    if (!formType) {
      return <Redirect to={PAGE_PATHS.BEGIN} />;
    } else if (this.editingClaimReview() && !processedAt) {
      return <Redirect to={PAGE_PATHS.NOT_EDITABLE} />;
    } else if (hasClearedEp) {
      return <Redirect to={PAGE_PATHS.CLEARED_EPS} />;
    } else if (intakeData.isOutcoded) {
      return <Redirect to={PAGE_PATHS.OUTCODED} />;
    }
  }

  establishmentCreditsTimestamp() {
    const tstamp = moment(this.props.processedAt).format('ddd MMM DD YYYY [at] HH:mm');

    if (this.props.asyncJobUrl) {
      return <a href={this.props.asyncJobUrl}>{tstamp}</a>;
    }

    return tstamp;
  }

  establishmentCredits() {
    return <div className="cf-intake-establish-credits">
      Established {this.establishmentCreditsTimestamp()}
      <span> by <a href={`/intake/manager?user_css_id=${this.props.intakeUser}`}>{this.props.intakeUser}</a></span>
    </div>;
  }

  render() {
    const { intakeForms, formType, veteran, featureToggles, editPage, addingIssue, userCanWithdrawIssues } = this.props;
    const intakeData = intakeForms[formType];
    const { useAmaActivationDate } = featureToggles;
    const hasClearedEp = intakeData && (intakeData.hasClearedRatingEp || intakeData.hasClearedNonratingEp);

    if (this.willRedirect(intakeData, hasClearedEp)) {
      return this.redirect(intakeData, hasClearedEp);
    }

    const requestState = intakeData.requestStatus.completeIntake || intakeData.requestStatus.requestIssuesUpdate;
    const requestErrorCode =
      intakeData.requestStatus.completeIntakeErrorCode || intakeData.requestIssuesUpdateErrorCode;
    const requestErrorUUID = intakeData.requestStatus.completeIntakeErrorUUID;
    const showInvalidVeteranError =
      !intakeData.veteranValid &&
      _.some(
        intakeData.addedIssues,
        (issue) => VBMS_BENEFIT_TYPES.includes(issue.benefitType) || issue.ratingIssueReferenceId
      );

    const issues = formatAddedIssues(intakeData.addedIssues, useAmaActivationDate);
    const requestedIssues = issues.filter((issue) => !issue.withdrawalPending && !issue.withdrawalDate);
    const previouslywithdrawnIssues = issues.filter((issue) => issue.withdrawalDate);
    const issuesPendingWithdrawal = issues.filter((issue) => issue.withdrawalPending);
    const withdrawnIssues = previouslywithdrawnIssues.concat(issuesPendingWithdrawal);
    const reducer = (result, issue) => accumulator + currentValue;
    const issuesBySection = issues.reduce(
      (result, issue, key) => {
        if (issue.withdrawalDate || issue.withdrawalPending) {
          (result["withdrawnIssues"] || (result["withdrawnIssues"] = [])).push(issue)
        } else if (issue.endProductCode) {
          (result[issue.endProductCode] || (result[issue.endProductCode] = [])).push(issue);
        } else {
          (result["requestedIssues"] || (result["requestedIssues"] = [])).push(issue)
        };

        return result;
      }, {}
    );

    console.log("issuesBySection::", issuesBySection);

    const withdrawReview =
      !_.isEmpty(issues) && _.every(issues, (issue) => issue.withdrawalPending || issue.withdrawalDate);

    const haveIssuesChanged = () => {
      const issueCountChanged = issues.length !== this.state.originalIssueLength;

      // If the entire review is withdrawn, then issues will have changed, but that
      // will be communicated differently so haveIssuesChanged will not be set to true
      const partialWithdrawal = !_.isEmpty(issuesPendingWithdrawal) && !withdrawReview;

      // if an new issue was added or an issue was edited
      const newOrChangedIssue =
        issues.filter((issue) => !issue.id || issue.editedDescription || issue.correctionType).length > 0;

      if (issueCountChanged || partialWithdrawal || newOrChangedIssue) {
        return true;
      }

      return false;
    };

    const addIssueButton = () => {
      return (
        <div className="cf-actions">
          <Button
            name="add-issue"
            legacyStyling={false}
            classNames={['usa-button-secondary']}
            onClick={() => this.onClickAddIssue()}
          >
            + Add issue
          </Button>
        </div>
      );
    };

    const messageHeader = editPage ? 'Edit Issues' : 'Add / Remove Issues';

    const withdrawError = () => {
      const withdrawalDate = new Date(intakeData.withdrawalDate);
      const currentDate = new Date();
      const receiptDate = new Date(intakeData.receiptDate);
      const formName = _.find(FORM_TYPES, { key: formType }).shortName;
      let msg;

      if (intakeData.withdrawalDate) {
        if (withdrawalDate < receiptDate) {
          msg = `We cannot process your request. Please select a date after the ${formName}'s receipt date.`;
        } else if (withdrawalDate > currentDate) {
          msg = "We cannot process your request. Please select a date prior to today's date.";
        }

        return msg;
      }
    };

    const columns = [{ valueName: 'field' }, { valueName: 'content' }];

    let fieldsForFormType = getAddIssuesFields(formType, veteran, intakeData);
    let issueChangeClassname = () => {
      // no-op unless the issue banner needs to be displayed
    };

    if (editPage && haveIssuesChanged()) {
      // flash a save message if user is on the edit page & issues have changed
      const issuesChangedBanner = <p>When you finish making changes, click "Save" to continue.</p>;

      fieldsForFormType = fieldsForFormType.concat({
        field: '',
        content: issuesChangedBanner
      });
      issueChangeClassname = (rowObj) => (rowObj.field === '' ? 'intake-issue-flash' : '');
    }

    let rowObjects = fieldsForFormType;
    console.log("requestedIssues::", requestedIssues);
    const endProducts = _.compact(requestedIssues.map((issue) => issue.endProductCode));
    console.log("endProducts::", endProducts);

    // End product issues each create the row objects
    // Remaining issues show in regular requested issues section
    // Show withdrawn issues

    const rowObjectForIssues = (issues, fieldTitle) => {
      return {
        field: fieldTitle,
        content: (
          <IssueList
            onClickIssueAction={this.onClickIssueAction}
            withdrawReview={withdrawReview}
            issues={issues}
            intakeData={intakeData}
            formType={formType}
            featureToggles={featureToggles}
            userCanWithdrawIssues={userCanWithdrawIssues}
            editPage={editPage}
          />
        )
      };
    };

    const claimLabelStyling = css({
      display: 'inline-block'
    });

    const buttonContainerStyling = css({
      display: 'inline-block',
      float: 'right',
      width: '140px',
      padding: '0',
      margin: '0'
    });

    const rowObjectForEndProduct = (endProductCode) => {
      return {
        field: "EP Claim Label",
        content: (
          <div className="claim-label-row" key={`claim-label-${endProductCode}`}>
            <div className="claim-label" {...claimLabelStyling}>
              <strong>{ EP_CLAIM_TYPES[endProductCode].official_label }</strong>
            </div>
            <div {...buttonContainerStyling}>
              <Button
                id="sally"
                onClick={() => console.log('"Edit claim label" clicked!')}
                classNames={['usa-button-secondary', 'edit-claim-label']}
              >
              Edit claim label
            </Button>
            </div>
          </div>
        )
      };
    };

    const rowObjectForEndProductIssues = (issues) => {
      return {
        field: "",
        content: (
          <div>
            <span><strong>Requested issues</strong></span>
            <IssueList
              onClickIssueAction={this.onClickIssueAction}
              withdrawReview={withdrawReview}
              issues={issues}
              intakeData={intakeData}
              formType={formType}
              featureToggles={featureToggles}
              userCanWithdrawIssues={userCanWithdrawIssues}
              editPage={editPage}
            />
        </div>
        )
      };
    };

    Object.keys(issuesBySection).map(function(key, index) {
      const sectionIssues = issuesBySection[key];
      if (key == 'requestedIssues') {
        rowObjects = rowObjects.concat(rowObjectForIssues(sectionIssues, 'Requested issues'));
      } else if (key == 'withdrawnIssues') {
        rowObjects = rowObjects.concat(rowObjectForIssues(sectionIssues, 'Withdrawn issues'));
      } else {
        rowObjects = rowObjects.concat(rowObjectForEndProduct(key));
        rowObjects = rowObjects.concat(rowObjectForEndProductIssues(sectionIssues));
      }
    });

    // if (!_.isEmpty(requestedIssues)) {
    //   // endProducts.forEach(endProduct => )
    //   rowObjects = fieldsForFormType.concat(rowObjectForIssues(requestedIssues, 'Requested issues'));
    // }
    //
    // if (!_.isEmpty(withdrawnIssues)) {
    //   rowObjects = rowObjects.concat(rowObjectForIssues(withdrawnIssues, 'Withdrawn issues'));
    // }

    const hideAddIssueButton = intakeData.isDtaError && _.isEmpty(intakeData.contestableIssues);

    if (!hideAddIssueButton) {
      rowObjects = rowObjects.concat({
        field: ' ',
        content: addIssueButton()
      });
    }

    return (
      <div className="cf-intake-edit">
        {this.state.addingIssue && (
          <AddIssueManager
            intakeData={intakeData}
            formType={formType}
            featureToggles={featureToggles}
            editPage={editPage}
            onComplete={() => {
              this.setState({ addingIssue: false });
            }}
          />
        )}

        {intakeData.removeIssueModalVisible && (
          <RemoveIssueModal
            removeIndex={this.state.issueRemoveIndex}
            intakeData={intakeData}
            closeHandler={this.props.toggleIssueRemoveModal}
          />
        )}
        {intakeData.correctIssueModalVisible && (
          <CorrectionTypeModal
            issueIndex={this.props.activeIssue}
            intakeData={intakeData}
            cancelText={addingIssue ? 'Cancel adding this issue' : 'Cancel'}
            onCancel={() => {
              this.props.toggleCorrectionTypeModal();
            }}
            submitText={addingIssue ? 'Continue' : 'Save'}
            onSubmit={({ correctionType }) => {
              this.props.correctIssue({
                index: this.props.activeIssue,
                correctionType
              });
              this.props.toggleCorrectionTypeModal();
            }}
          />
        )}
        <h1 className="cf-txt-c">{messageHeader}</h1>

        {requestState === REQUEST_STATE.FAILED && (
          <ErrorAlert errorCode={requestErrorCode} errorUUID={requestErrorUUID} />
        )}

        {showInvalidVeteranError && (
          <ErrorAlert errorCode="veteran_not_valid" errorData={intakeData.veteranInvalidFields} />
        )}

        {editPage && this.establishmentCredits()}

        <Table columns={columns} rowObjects={rowObjects} rowClassNames={issueChangeClassname} slowReRendersAreOk />

        {!_.isEmpty(issuesPendingWithdrawal) && (
          <div className="cf-gray-box cf-decision-date">
            <InlineForm>
              <DateSelector
                label={COPY.INTAKE_EDIT_WITHDRAW_DATE}
                name="withdraw-date"
                value={intakeData.withdrawalDate}
                onChange={this.withdrawalDateOnChange}
                dateErrorMessage={withdrawError()}
                type="date"
              />
            </InlineForm>
          </div>
        )}
      </div>
    );
  }
}

AddIssuesPage.propTypes = {
  activeIssue: PropTypes.number,
  addingIssue: PropTypes.bool,
  correctIssue: PropTypes.func,
  editPage: PropTypes.bool,
  featureToggles: PropTypes.object,
  formType: PropTypes.oneOf(_.map(FORM_TYPES, 'key')),
  intakeForms: PropTypes.object,
  removeIssue: PropTypes.func,
  setIssueWithdrawalDate: PropTypes.func,
  toggleAddingIssue: PropTypes.func,
  toggleAddIssuesModal: PropTypes.func,
  toggleCorrectionTypeModal: PropTypes.func,
  toggleIssueRemoveModal: PropTypes.func,
  toggleLegacyOptInModal: PropTypes.func,
  toggleNonratingRequestIssueModal: PropTypes.func,
  toggleUnidentifiedIssuesModal: PropTypes.func,
  toggleUntimelyExemptionModal: PropTypes.func,
  undoCorrection: PropTypes.func,
  veteran: PropTypes.object,
  withdrawIssue: PropTypes.func,
  userCanWithdrawIssues: PropTypes.bool
};

export const IntakeAddIssuesPage = connect(
  ({ intake, higherLevelReview, supplementalClaim, appeal, featureToggles, activeIssue, addingIssue }) => ({
    intakeForms: {
      higher_level_review: higherLevelReview,
      supplemental_claim: supplementalClaim,
      appeal
    },
    formType: intake.formType,
    veteran: intake.veteran,
    featureToggles,
    activeIssue,
    addingIssue
  }),
  (dispatch) =>
    bindActionCreators(
      {
        toggleAddIssuesModal,
        toggleUntimelyExemptionModal,
        toggleNonratingRequestIssueModal,
        toggleUnidentifiedIssuesModal,
        toggleLegacyOptInModal,
        removeIssue,
        withdrawIssue,
        setIssueWithdrawalDate
      },
      dispatch
    )
)(AddIssuesPage);

export const EditAddIssuesPage = connect(
  (state) => ({
    intakeForms: {
      higher_level_review: state,
      supplemental_claim: state,
      appeal: state
    },
    processedAt: state.processedAt,
    intakeUser: state.intakeUser,
    asyncJobUrl: state.asyncJobUrl,
    formType: state.formType,
    veteran: state.veteran,
    featureToggles: state.featureToggles,
    editPage: true,
    activeIssue: state.activeIssue,
    addingIssue: state.addingIssue,
    userCanWithdrawIssues: state.userCanWithdrawIssues
  }),
  (dispatch) =>
    bindActionCreators(
      {
        toggleAddingIssue,
        toggleIssueRemoveModal,
        toggleCorrectionTypeModal,
        removeIssue,
        withdrawIssue,
        setIssueWithdrawalDate,
        correctIssue,
        undoCorrection,
        toggleUnidentifiedIssuesModal
      },
      dispatch
    )
)(AddIssuesPage);
