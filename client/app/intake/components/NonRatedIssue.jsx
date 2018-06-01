import React from 'react';
import SearchableDropdown from '../../components/SearchableDropdown';
import TextField from '../../components/TextField';
import Button from '../../components/Button';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { setIssueCategory, setIssueDescription } from '../actions/common';
import { ISSUE_CATEGORIES} from '../constants'

class NonRatedIssue extends React.PureComponent {
  handleCategoryChange(event) {
    this.props.setIssueCategory(this.props.issueId, event.value);
  }

  handleDescriptionChange(event) {
    this.props.setIssueDescription(this.props.issueId, event);
  }

  render () {
    return (
      <div className="cf-non-rated-issue" key={this.props.key}>
        <SearchableDropdown
          name="issue-category"
          label="Issue category"
          placeholder="Select or enter..."
          options={ISSUE_CATEGORIES}
          value={this.props.appeal.nonRatedIssues[this.props.issueId] ? this.props.appeal.nonRatedIssues[this.props.issueId].issueCategory : null}
          onChange={event => this.handleCategoryChange(event)} />

        <TextField
          name="Issue description"
          value={this.props.appeal.nonRatedIssues[this.props.issueId] ? this.props.appeal.nonRatedIssues[this.props.issueId].issueDescription : null}
          onChange={event => this.handleDescriptionChange(event)} />

          <Button
            name="save-issue"
            legacyStyling={false}
          >
            Save
          </Button>
      </div>
    )
  }
};

const NonRatedIssueConnected = connect(
  ({ appeal }) => ({
    appeal
  }),
  (dispatch) => bindActionCreators({
    setIssueCategory,
    setIssueDescription
  }, dispatch)
)(NonRatedIssue);

export default NonRatedIssueConnected;

// class NonRatedIssue extends React.PureComponent {
//   setIssueCategoryFromDropdown = (issueCategory) => {
//     this.props.setIssueCategory(issueCategory.value);
//   }
//
//   render() {
//     return <div>
//       <SearchableDropdown
//         name="issue-category"
//         label="Issue category"
//         placeholder="Select or enter..."
//         options={ISSUE_CATEGORIES}
//         onChange={this.setIssueCategoryFromDropdown}
//         value={this.props.issueCategory} />
//
//       <TextField
//         name="Issue description"
//         onChange={this.onEmailChange}
//         errorMessage={this.state.certificationCancellationForm.email.errorMessage}
//         value={this.state.emailValue} />
//     </div>;
//   }
// }
//
// export default connect(
//   ({ intake }) => ({
//     formType: intake.formType,
//     intakeId: intake.id
//   }),
//   (dispatch) => bindActionCreators({
//     setIssueCategory
//   }, dispatch)
// )(NonRatedIssue);
//
// class SaveIssueButtonUnconnected extends React.PureComponent {
//   handleClick = () => {
//     this.props.saveIssue();
//   }
//
//   render = () =>
//     <Button
//       name="save-issue"
//       onClick={this.handleClick}
//       legacyStyling={false}
//     >
//       Save
//     </Button>;
// }
//
// export const SaveFormButton = connect(
//   ({ intake }) => ({ formType: intake.formType }),
//   (dispatch) => bindActionCreators({
//     clearSearchErrors
//   }, dispatch)
// )(SelectFormButtonUnconnected);
