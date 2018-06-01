import { after, css, merge } from 'glamor';
import PropTypes from 'prop-types';
import React from 'react';

import SelectCheckoutFlowDropdown from './components/SelectCheckoutFlowDropdown';
import COPY from '../../COPY.json';
import { COLORS } from '../constants/AppConstants';
import { renderAppealType } from './utils';
import { DateString } from '../util/DateUtil';

const snapshotParentContainerStyling = css({
  backgroundColor: COLORS.GREY_BACKGROUND,
  display: 'flex',
  lineHeight: '3rem',
  marginTop: '3rem',
  padding: '2rem 0',
  '& > div': { padding: '0 3rem 0 0' },
  '& > div:not(:last-child)': { borderRight: `1px solid ${COLORS.GREY_LIGHT}` },
  '& > div:first-child': { paddingLeft: '3rem' },

  '& .Select': { maxWidth: '100%' }
});

const definitionListStyling = css({
  margin: '0',
  '& dt': merge(
    after({ content: ':' }),
    {
      float: 'left',
      fontSize: '1.5rem',
      marginRight: '0.5rem'
    }
  )
});

const aboutListStyling = css({
  '& dt': {
    color: COLORS.GREY_MEDIUM,
    textTransform: 'uppercase'
  }
});

const assignmentListStyling = css({
  '& dt': { fontWeight: 'bold' }
});

const aboutHeadingStyling = css({
  marginBottom: '0.5rem'
});

// TODO: Move the copy into COPY.json
// TODO: Separate the design and application code?
export default class CaseSnapshot extends React.PureComponent {
  daysSinceTaskAssignmentListItem = () => {
    if (this.props.task) {
      const today = new Date();
      const dateAssigned = new Date(this.props.task.attributes.assigned_on);
      const dayCountSinceAssignment = Math.round(Math.abs((today - dateAssigned) / (24 * 60 * 60 * 1000)));

      return <React.Fragment><dt>Total days waiting</dt><dd>{dayCountSinceAssignment}</dd></React.Fragment>;
    }

    return null;
  };

  taskAssignmentListItems = () => {
    const assignedToListItem = <React.Fragment>
      <dt>Assigned to</dt><dd>{this.props.appeal.attributes.location_code}</dd>
    </React.Fragment>;

    if (!this.props.task) {
      return assignedToListItem;
    }

    const task = this.props.task.attributes;

    if (this.props.userRole === 'Judge') {
      if (!task.assigned_by_first_name || !task.assigned_by_last_name || !task.document_id) {
        return assignedToListItem;
      }

      const firstInitial = String.fromCodePoint(task.assigned_by_first_name.codePointAt(0));
      const nameAbbrev = `${firstInitial}. ${task.assigned_by_last_name}`;

      return <React.Fragment>
        <dt>Prepared by</dt><dd>{nameAbbrev}</dd>
        <dt>Document ID</dt><dd>{task.document_id}</dd>
      </React.Fragment>;
    }

    return <React.Fragment>
      {task.added_by_name ? <React.Fragment><dt>Assigned by</dt><dd>{task.added_by_name}</dd></React.Fragment> : null }
      <dt>Assigned on</dt><dd><DateString date={task.assigned_on} dateFormat="MM/DD/YY" /></dd>
      <dt>Due</dt><dd><DateString date={task.due_on} dateFormat="MM/DD/YY" /></dd>
    </React.Fragment>;
  };

  render = () => {
    return <div className="usa-grid" {...snapshotParentContainerStyling}>
      <div className="usa-width-one-fourth">
        <h3 {...aboutHeadingStyling}>{COPY.CASE_SNAPSHOT_ABOUT_BOX_TITLE}</h3>
        <dl {...definitionListStyling} {...aboutListStyling}>
          <dt>Type</dt><dd>{renderAppealType(this.props.appeal)}</dd>
          <dt>Docket</dt><dd>{this.props.appeal.attributes.docket_number}</dd>
          {this.daysSinceTaskAssignmentListItem()}
        </dl>
      </div>
      <div className="usa-width-one-fourth">
        <dl {...definitionListStyling} {...assignmentListStyling}>
          {this.taskAssignmentListItems()}
        </dl>
      </div>
      {/* TODO: Make the dropdown box go the full width here. */}
      <div className="usa-width-one-half">
        <h3>Actions</h3>
        <SelectCheckoutFlowDropdown vacolsId={this.props.appeal.attributes.vacols_id} />
      </div>
    </div>;
  };
}

CaseSnapshot.propTypes = {
  appeal: PropTypes.object.isRequired,
  task: PropTypes.object,
  userRole: PropTypes.string
};
