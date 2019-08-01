import React from 'react';
import { css } from 'glamor';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import moment from 'moment';
import _ from 'lodash';
import LEGACY_APPEAL_TYPES_BY_ID from '../../../constants/LEGACY_APPEAL_TYPES_BY_ID.json';

import { sortHearings } from '../utils';
import COPY from '../../../COPY.json';
import Table from '../../components/Table';
import TabWindow from '../../components/TabWindow';
import DocketTypeBadge from '../../components/DocketTypeBadge';
import { renderAppealType } from '../../queue/utils';
import { getTime, getTimeInDifferentTimeZone } from '../../util/DateUtil';
import StatusMessage from '../../components/StatusMessage';
import { getFacilityType } from '../../components/DataDropdowns/AppealHearingLocations';
import { getIndexOfDocketLine, docketCutoffLineStyle } from './AssignHearingsDocketLine';

const tableNumberStyling = css({
  '& tr > td:first-child': {
    paddingRight: 0
  },
  '& td:nth-child(2)': {
    paddingLeft: 0
  }
});

const UPCOMING_HEARINGS_TAB_NAME = 'upcomingHearings';

const AvailableVeteransTable = ({ rows, columns, style = {} }) => {
  let removeTimeColumn = _.slice(columns, 0, -1);

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

  return <span {...style}>
    <Table
      columns={removeTimeColumn}
      rowObjects={rows}
      summary="scheduled-hearings-table"
      slowReRendersAreOk
      bodyStyling={tableNumberStyling} />
  </span>;
};

const UpcomingHearingsTable = ({ rows, columns, selectedHearingDay }) => {
  if (_.isNil(selectedHearingDay)) {
    return <StatusMessage
      title={COPY.ASSIGN_HEARINGS_TABS_NO_HEARING_DAY_HEADER}
      type="alert"
      messageText={COPY.ASSIGN_HEARINGS_TABS_NO_HEARING_DAY_MESSAGE}
      wrapInAppSegment={false}
    />;
  }

  return <div>
    <Link to={`/schedule/docket/${selectedHearingDay.id}`}>
      {`View the Daily Docket for ${moment(selectedHearingDay.scheduledFor).format('M/DD/YYYY')}` }
    </Link>
    <Table
      columns={columns}
      rowObjects={rows}
      summary="scheduled-hearings-table"
      slowReRendersAreOk
      bodyStyling={tableNumberStyling}
    />
  </div>;
};

export default class AssignHearingsTabs extends React.Component {

  constructor(props) {
    super(props);
  }

  isAmaAppeal = (appeal) => {
    return appeal.attributes.appealType === 'Appeal';
  };

  getHearingTime = (date, regionalOfficeTimezone) => {

    if (this.props.selectedRegionalOffice === 'C') {
      return <div>{getTime(date)} </div>;
    }

    return <div>
      {getTime(date)} /<br />{getTimeInDifferentTimeZone(date, regionalOfficeTimezone)}
    </div>;
  };

  appellantName = (hearingDay) => {
    let { appellantFirstName, appellantLastName, veteranFirstName, veteranLastName, veteranFileNumber } = hearingDay;

    if (appellantFirstName && appellantLastName) {
      return `${appellantFirstName} ${appellantLastName} | ${veteranFileNumber}`;
    } else if (veteranFirstName && veteranLastName) {
      return `${veteranFirstName} ${veteranLastName} | ${veteranFileNumber}`;
    }

    return `${veteranFileNumber}`;
  };

  getCaseDetailsInformation = (appeal) => {
    if (appeal.attributes.appellantFullName) {
      return `${appeal.attributes.appellantFullName} | ${appeal.attributes.veteranFileNumber}`;
    }

    return `${appeal.attributes.veteranFullName} | ${appeal.attributes.veteranFileNumber}`;
  };

  getHearingDocketTag = (hearing) => {
    if (hearing.docketNumber) {
      return <div>
        <DocketTypeBadge name={hearing.docketName} number={hearing.docketNumber} />
        {hearing.docketNumber}
      </div>;
    }

  };

  getAppealDocketTag = (appeal) => {
    if (appeal.attributes.docketNumber) {
      return <div>
        <DocketTypeBadge name={appeal.attributes.docketName} number={appeal.attributes.docketNumber} />
        {appeal.attributes.docketNumber}
      </div>;
    }
  };

  getSuggestedHearingLocation = (locations) => {
    if (!locations || locations.length === 0) {
      return '';
    }

    /* Sort available locations before selecting top one. */
    const sortedLocations = _.orderBy(locations, ['distance'], ['asc']);

    /* Select first entry which should be shortest distance. */
    const location = sortedLocations[0];

    return this.formatSuggestedHearingLocation(location);

  };

  formatSuggestedHearingLocation = (location) => {
    if (!location) {
      return '';
    }

    const { city, state, distance } = location;

    return (
      <span>
        <div>{`${city}, ${state} ${getFacilityType(location)}`}</div>
        {!_.isNil(distance) &&
          <div>{`Distance: ${distance} miles away`}</div>
        }
      </span>
    );
  }

  availableVeteransRows = (appeals) => {
    /*
      Sorting by docket number within each category of appeal:
      CAVC, AOD and normal. Prepended * and + to docket number for
      CAVC and AOD to group them first and second.
     */
    const sortedByAodCavc = _.sortBy(appeals, (appeal) => {
      if (appeal.attributes.caseType === LEGACY_APPEAL_TYPES_BY_ID.cavc_remand) {
        return `*${appeal.attributes.docketNumber}`;
      } else if (appeal.attributes.aod) {
        return `+${appeal.attributes.docketNumber}`;
      }

      return appeal.attributes.docketNumber;
    });

    return _.map(sortedByAodCavc, (appeal, index) => ({
      number: <span>{index + 1}.</span>,
      caseDetails: this.getCaseDetailsInformation(appeal),
      type: renderAppealType({
        caseType: appeal.attributes.caseType,
        isAdvancedOnDocket: appeal.attributes.aod
      }),
      docketNumber: this.getAppealDocketTag(appeal),
      suggestedLocation: this.getSuggestedHearingLocation(appeal.attributes.availableHearingLocations),
      time: null,
      externalId: appeal.attributes.externalAppealId
    }));
  };

  upcomingHearingsRows = (hearings) => {
    return _.map(hearings, (hearing, index) => ({
      number: <span>{index + 1}.</span>,
      externalId: hearing.appealExternalId,
      caseDetails: this.appellantName(hearing),
      type: renderAppealType({
        caseType: hearing.appealType,
        isAdvancedOnDocket: hearing.aod
      }),
      docketNumber: this.getHearingDocketTag(hearing),
      hearingLocation: hearing.readableLocation,
      time: this.getHearingTime(hearing.scheduledFor, hearing.regionalOfficeTimezone)
    }));
  };

  tabWindowColumns = (data, { tab }) => {
    const { selectedRegionalOffice, selectedHearingDay } = this.props;

    let locationColumn;
    if (tab === UPCOMING_HEARINGS_TAB_NAME) {
      locationColumn = {
        name: 'Hearing Location',
        header: 'Hearing Location',
        align: 'left',
        columnName: 'hearingLocation',
        valueName:  'hearingLocation',
        tableData: data,
        anyFiltersAreSet: true,
        enableFilter: true,
        enableFilterTextTransform: false
      };
    } else {
      locationColumn = {
        name: 'Suggested Location',
        header: 'Suggested Location',
        align: 'left',
        columnName: 'suggestedLocation',
        valueFunction: this.getSuggestedHearingLocationForDisplay,
        filterValueTransform: this.formatSuggestedHearingLocation,
        tableData: data,
        anyFiltersAreSet: true,
        enableFilter: true,
        enableFilterTextTransform: false
      };
    }

    return [{
      header: '',
      align: 'left',
      valueName: 'number'
    },
    {
      header: 'Case details',
      align: 'left',
      valueName: 'caseDetails',
      valueFunction: (appeal) => <Link
        name={appeal.externalId}
        href={(() => {
          const date = moment(selectedHearingDay.scheduledFor).format('YYYY-MM-DD');
          const qry = `?hearingDate=${date}&regionalOffice=${selectedRegionalOffice}`;

          return `/queue/appeals/${appeal.externalId}/${qry}`;
        })()}>
        {appeal.caseDetails}
      </Link>
    },
    {
      header: 'Type(s)',
      align: 'left',
      valueName: 'type'
    },
    {
      header: 'Docket number',
      align: 'left',
      valueName: 'docketNumber'
    },
    {
      header: tab === UPCOMING_HEARINGS_TAB_NAME ? 'Hearing Location' : 'Suggested Location',
      align: 'left',
      valueName: tab === UPCOMING_HEARINGS_TAB_NAME ? 'hearingLocation' : 'suggestedLocation',
      getFilterValues: locationFilterValues,
      isDropdownFilterOpen: state.dropdownIsOpen,
      label: 'Filter by location',
      anyFiltersAreSet: false,
      toggleDropdownFilterVisibility: () => this.setState({
        [tab]: {
          ...state,
          dropdownIsOpen: !state.dropdownIsOpen
        }
      }),
      setSelectedValue: (val) => {
        this.setState({
          [tab]: {
            dropdownIsOpen: false,
            filteredBy: val === 'all' ? null : val
          }
        });
      }
    },
    {
      header: 'Time',
      align: 'left',
      valueName: 'time'
    }];
  }

  amaDocketCutoffLineStyle = (appeals) => {
    const endOfNextMonth = moment().add('months', 1).endOf('month');
    const indexOfLine = getIndexOfDocketLine(appeals, endOfNextMonth);

    return docketCutoffLineStyle(indexOfLine, endOfNextMonth.format('MMMM YYYY'));
  }

  render() {
    const { selectedHearingDay, appealsReadyForHearing, room } = this.props;

    const hearingsForSelected = _.get(selectedHearingDay, 'hearings', []);
    const availableSlots = _.get(selectedHearingDay, 'totalSlots', 0) - Object.keys(hearingsForSelected).length;

    const upcomingHearings = sortHearings(hearingsForSelected);
    const amaAppeals = _.filter(appealsReadyForHearing, (appeal) => this.isAmaAppeal(appeal));
    const legacyAppeals = _.filter(appealsReadyForHearing, (appeal) => !this.isAmaAppeal(appeal));

    return <div className="usa-width-three-fourths" {...filterDropdownFix}>
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
              selectedHearingDay={selectedHearingDay}
              rows={this.upcomingHearingsRows(upcomingHearings)}
              columns={this.tabWindowColumns(upcomingHearings, { tab: UPCOMING_HEARINGS_TAB_NAME })}
            />
          },
          {
            label: 'Legacy Veterans Waiting',
            page: <AvailableVeteransTable
              rows={this.availableVeteransRows(legacyAppeals, { tab: 'legacyAppeals' })}
              columns={this.tabWindowColumns(legacyAppeals, { tab: 'legacyAppeals' })}
            />
          },
          {
            label: 'AMA Veterans Waiting',
            page: <AvailableVeteransTable
              style={this.amaDocketCutoffLineStyle(amaAppeals)}
              rows={this.availableVeteransRows(amaAppeals, { tab: 'amaAppeals' })}
              columns={this.tabWindowColumns(amaAppeals, { tab: 'amaAppeals' })}
            />
          }
        ]}
      />
    </div>;
  }
}
