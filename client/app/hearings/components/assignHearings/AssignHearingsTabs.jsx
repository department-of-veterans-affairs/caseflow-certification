import { connect } from 'react-redux';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import PropTypes from 'prop-types';
import React from 'react';
import _ from 'lodash';
import moment from 'moment';

import { AppealDocketTag, SuggestedHearingLocation, CaseDetailsInformation } from './AssignHearingsFields';
import { NoUpcomingHearingDayMessage } from './Messages';
import { getFacilityType } from '../../../components/DataDropdowns/AppealHearingLocations';
import { getIndexOfDocketLine, docketCutoffLineStyle } from './AssignHearingsDocketLine';
import { renderAppealType } from '../../../queue/utils';
import AssignHearingsTable from './AssignHearingsTable';
import PowerOfAttorneyDetail from '../../../queue/PowerOfAttorneyDetail';
import QUEUE_CONFIG from '../../../../constants/QUEUE_CONFIG.json';
import TabWindow from '../../../components/TabWindow';
import UpcomingHearingsTable from './UpcomingHearingsTable';

const AvailableVeteransTable = ({ style = {}, selectedHearingDay, ...props }) => {
  if (_.isNil(selectedHearingDay)) {
    return <NoUpcomingHearingDayMessage />;
  }

  /*
  if (_.isEmpty(rows)) {
    return <div>
      <StatusMessage
        title= {COPY.ASSIGN_HEARINGS_TABS_VETERANS_NOT_ASSIGNED_HEADER}
        type="alert"
        messageText={COPY.ASSIGN_HEARINGS_TABS_VETERANS_NOT_ASSIGNED_MESSAGE}
        wrapInAppSegment={false}
      />
    </div>;
  }
  */

  return (
    <span {...style}>
      <AssignHearingsTable selectedHearingDay={selectedHearingDay} {...props} />
    </span>
  );
};

AvailableVeteransTable.propTypes = {
  style: PropTypes.object,
  selectedHearingDay: PropTypes.shape({
    id: PropTypes.number,
    scheduledFor: PropTypes.string
  })
};

export class AssignHearingsTabs extends React.PureComponent {

  amaDocketCutoffLineStyle = (appeals) => {
    const endOfNextMonth = moment().add(1, 'months').
      endOf('month');
    const indexOfLine = getIndexOfDocketLine(appeals, endOfNextMonth);

    return docketCutoffLineStyle(indexOfLine, endOfNextMonth.format('MMMM YYYY'));
  }

  render() {
    const {
      selectedHearingDay,
      selectedRegionalOffice,
      displayPowerOfAttorneyColumn,
      room
    } = this.props;

    const hearingsForSelected = _.get(selectedHearingDay, 'hearings', {});
    const availableSlots = _.get(selectedHearingDay, 'totalSlots', 0) - Object.keys(hearingsForSelected).length;

    // Remove when pagination lands (#11757)
    return <div className="usa-width-three-fourths">
      {!_.isNil(selectedHearingDay) && <h1>
        {`${moment(selectedHearingDay.scheduledFor).format('ddd M/DD/YYYY')}
          ${room} (${availableSlots} slots remaining)`}
      </h1>}
      <TabWindow
        name="scheduledHearings-tabwindow"
        tabs={[
          {
            label: 'Scheduled Veterans',
            page: <UpcomingHearingsTable
              selectRegionalOffice={selectedRegionalOffice}
              selectedHearingDay={selectedHearingDay}
              hearings={hearingsForSelected}
            />
          },
          {
            label: 'Legacy Veterans Waiting',
            page: <AvailableVeteransTable
              selectedHearingDay={selectedHearingDay}
              selectedRegionalOffice={selectedRegionalOffice}
              displayPowerOfAttorneyColumn={displayPowerOfAttorneyColumn}
              tabName={QUEUE_CONFIG.LEGACY_ASSIGN_HEARINGS_TAB_NAME}
            />
          },
          {
            label: 'AMA Veterans Waiting',
            page: <AvailableVeteransTable
              selectedHearingDay={selectedHearingDay}
              selectedRegionalOffice={selectedRegionalOffice}
              displayPowerOfAttorneyColumn={displayPowerOfAttorneyColumn}
              tabName={QUEUE_CONFIG.AMA_ASSIGN_HEARINGS_TAB_NAME}
            />
          }
        ]}
      />
    </div>;
  }
}

const appealPropTypes = PropTypes.shape({
  attributes: PropTypes.shape({
    caseType: PropTypes.string,
    docketNumber: PropTypes.string,
    aod: PropTypes.bool,
    availableHearingLocations: PropTypes.array,
    externalAppealId: PropTypes.string
  })
});

AssignHearingsTabs.propTypes = {
  selectedHearingDay: PropTypes.shape({
    hearings: PropTypes.object,
    id: PropTypes.number,
    regionalOffice: PropTypes.string,
    regionalOfficeKey: PropTypes.string,
    requestType: PropTypes.string,
    room: PropTypes.string,
    scheduledFor: PropTypes.string,
    totalSlots: PropTypes.number
  }),
  selectedRegionalOffice: PropTypes.string,
  room: PropTypes.string,
  // Appeal ID => Attorney Name Array
  powerOfAttorneyNamesForAppeals: PropTypes.objectOf(PropTypes.string),
  // Remove when pagination lands (#11757)
  displayPowerOfAttorneyColumn: PropTypes.bool
};

AssignHearingsTabs.defaultProps = {
  powerOfAttorneyNamesForAppeals: {}
};

const mapStateToProps = (state) => {
  const powerOfAttorneyNamesForAppeals = _.mapValues(
    _.get(state, 'queue.appealDetails', {}),
    (val) => _.get(val, 'powerOfAttorney.representative_name')
  );

  return { powerOfAttorneyNamesForAppeals };
};

export default connect(mapStateToProps)(AssignHearingsTabs);
