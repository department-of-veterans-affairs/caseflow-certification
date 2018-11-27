import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import _ from 'lodash';

import decisionViewBase from './components/DecisionViewBase';
import SelectIssueDispositionDropdown from './components/SelectIssueDispositionDropdown';
import Modal from '../components/Modal';
import TextareaField from '../components/TextareaField';
import SearchableDropdown from '../components/SearchableDropdown';
import ContestedIssues from './components/ContestedIssues';
import COPY from '../../COPY.json';

import {
  updateEditingAppealIssue,
  setDecisionOptions,
  startEditingAppealIssue,
  saveEditedAppealIssue
} from './QueueActions';
import { hideSuccessMessage } from './uiReducer/uiActions';
import {
  PAGE_TITLES,
  VACOLS_DISPOSITIONS,
  ISSUE_DISPOSITIONS
} from './constants';
import USER_ROLE_TYPES from '../../constants/USER_ROLE_TYPES.json';

import BENEFIT_TYPES from '../../constants/BENEFIT_TYPES.json';

class SelectDispositionsView extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      issuesOpen: null
    };
  }

  getPageName = () => PAGE_TITLES.DISPOSITIONS[this.props.userRole.toUpperCase()];

  getNextStepUrl = () => {
    const {
      appealId,
      taskId,
      checkoutFlow,
      userRole,
      appeal: { issues }
    } = this.props;
    let nextStep;
    const dispositions = issues.map((issue) => issue.disposition);
    const remandedIssues = _.some(dispositions, (disp) => [
      VACOLS_DISPOSITIONS.REMANDED, ISSUE_DISPOSITIONS.REMANDED
    ].includes(disp));

    if (remandedIssues) {
      nextStep = 'remands';
    } else if (userRole === USER_ROLE_TYPES.judge) {
      nextStep = 'evaluate';
    } else {
      nextStep = 'submit';
    }

    return `/queue/appeals/${appealId}/tasks/${taskId}/${checkoutFlow}/${nextStep}`;
  }

  getPrevStepUrl = () => {
    const {
      appealId,
      taskId,
      checkoutFlow,
      appeal
    } = this.props;

    return `/queue/appeals/${appealId}/tasks/${taskId}/${checkoutFlow}/special_issues`;
  }

  addDecisionHandler = (issueIds) => () => {
    this.setState({
      issuesOpen: issueIds
    });
  }

  handleModalClose = () => {
    this.setState({
      issuesOpen: null
    });
  }

  selectedIssues = () => {
    if (!this.state.issuesOpen) {
      return [];
    }

    return this.props.appeal.issues.filter((issue) => {
      return this.state.issuesOpen.includes(issue.id);
    });
  }

  render = () => {
    const { appeal } = this.props;
    const issue = this.selectedIssues()[0];

    return <React.Fragment>
      <ContestedIssues
        requestIssues={appeal.issues}
        addDecisionHandler={this.addDecisionHandler}
      />
      { this.state.issuesOpen && <Modal
        buttons = {[
          { classNames: ['cf-modal-link', 'cf-btn-link'],
            name: 'Close',
            onClick: this.handleModalClose
          },
          { classNames: ['usa-button', 'usa-button-secondary'],
            name: 'Proceed with action',
            onClick: this.handleModalClose
          }
        ]}
        closeHandler={this.handleModalClose}
        title = "Add decision">

        <h3>{COPY.DECISION_ISSUE_MODAL_TITLE}</h3>
        <p>{COPY.DECISION_ISSUE_MODAL_SUB_TITLE}</p>

        <h3>{COPY.DECISION_ISSUE_MODAL_DESCRIPTION}</h3>
        <TextareaField
          label={COPY.DECISION_ISSUE_MODAL_DESCRIPTION_EXAMPLE}
          name="Text Box"
          onChange={(value) => {
            this.setState({ value });
          }}
          value={this.state.value}
        />
        <h3>{COPY.DECISION_ISSUE_MODAL_DISPOSITION}</h3>
        <SelectIssueDispositionDropdown
          issue={issue}
          appeal={appeal}
          noStyling
        />
        <br />
        <h3>{COPY.DECISION_ISSUE_MODAL_BENEFIT_TYPE}</h3>
        <SearchableDropdown
          value={issue.benefitType}
          options={_.map(BENEFIT_TYPES, (value, key) => ({ label: value,
            value: key }))}
        />

      </Modal>}
    </React.Fragment>;
  };
}

SelectDispositionsView.propTypes = {
  appealId: PropTypes.string.isRequired,
  checkoutFlow: PropTypes.string.isRequired,
  userRole: PropTypes.string.isRequired
};

const mapStateToProps = (state, ownProps) => ({
  appeal: state.queue.stagedChanges.appeals[ownProps.appealId],
  success: state.ui.messages.success,
  ..._.pick(state.ui, 'userRole')
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  updateEditingAppealIssue,
  setDecisionOptions,
  startEditingAppealIssue,
  saveEditedAppealIssue,
  hideSuccessMessage
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(decisionViewBase(SelectDispositionsView));
