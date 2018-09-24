// @flow
import * as React from 'react';
import { css } from 'glamor';

import IssueListItem from './IssueListItem';
import LegacyIssueListItem from './LegacyIssueListItem';
import { NO_ISSUES_ON_APPEAL_MSG } from '../../reader/constants';

const tableContainerStyling = (fluid) => css({
  width: fluid ? '100%' : '75rem',
  '> table': {
    marginTop: fluid ? '0rem' : '1rem',
    marginBottom: '1rem',
    '& td': {
      verticalAlign: 'top',
      border: 'none',
      paddingTop: 0,
      backgroundColor: 'inherit'
    }
  }
});
const bottomBorder = (singleIssue) => css({
  borderBottom: singleIssue ? 'none !important' : ''
});

import type {
  Issue
} from '../types/models';

type Props = {
  appeal: { issues: Array<Issue>, isLegacyAppeal: boolean },
  idxToDisplay?: number,
  issuesOnly?: boolean,
  stretchToFullWidth?: boolean
};

export default class IssueList extends React.PureComponent<Props> {
  getIssues = () => {
    const {
      appeal: {
        issues,
        isLegacyAppeal
      }
    } = this.props;
    const singleIssue = issues.length === 1;
    const ListItem = isLegacyAppeal ? LegacyIssueListItem : IssueListItem;

    if (!issues.length) {
      return <tr>
        <td>{NO_ISSUES_ON_APPEAL_MSG}</td>
      </tr>;
    }

    return <React.Fragment>{issues.map((issue, idx) => {
      // this component is used in Reader, where issue ids are only `vacols_sequence_id`
      const issueId = String(isLegacyAppeal ? issue.vacols_sequence_id : issue.id);

      return <tr key={`${issueId}_${issueId}`} {...bottomBorder(singleIssue)}>
        <ListItem issue={issue} idx={this.props.idxToDisplay || (idx + 1)} {...this.props} />
      </tr>;
    })}
    </React.Fragment>;
  };

  render = () => <div {...tableContainerStyling(this.props.issuesOnly || this.props.stretchToFullWidth)}>
    <table>
      <tbody>
        {this.getIssues()}
      </tbody>
    </table>
  </div>;
}
