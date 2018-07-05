import React from 'react';
import Checkbox from '../../components/Checkbox';
import { formatDateStr } from '../../util/DateUtil';
import _ from 'lodash';

export default class RatedIssuesUnconnected extends React.PureComponent {
  onCheckIssue = (profileDate, issueId) => (checked) => this.props.setIssueSelected(profileDate, issueId, checked)

  render() {

    const { reviewState } = this.props;

    const ratedIssuesSections = _.map(reviewState.ratings, (rating) => {
      const ratedIssueCheckboxes = _.map(rating.issues, (issue) => {
        return (
          <Checkbox
            label={issue.decision_text}
            name={issue.reference_id}
            key={issue.reference_id}
            value={issue.isSelected || false}
            onChange={this.onCheckIssue(rating.profile_date, issue.reference_id)}
            unpadded
          />
        );
      });

      return (<div className="cf-intake-ratings" key={rating.profile_date}>
        <h3>
          Decision date: { formatDateStr(rating.promulgation_date) }
        </h3>

        { ratedIssueCheckboxes }
      </div>
      );
    });

    return <div>
      <h2>Select from previous decision issues</h2>
      { ratedIssuesSections }
    </div>;
  }
}
