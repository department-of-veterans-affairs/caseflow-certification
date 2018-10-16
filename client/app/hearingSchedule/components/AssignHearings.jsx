import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import COPY from '../../../COPY.json';
import Button from '../../components/Button';
import TabWindow from '../../components/TabWindow';
import Table from '../../components/Table';
import RoSelectorDropdown from './RoSelectorDropdown';
import moment from 'moment';
import { css } from 'glamor';
import { COLORS } from '../../constants/AppConstants';
import { getTime, getTimeInDifferentTimeZone } from '../../util/DateUtil';

const colorAOD = css({
  color: 'red'
});

const centralOfficeStaticEntry = [{
  label: 'Central',
  value: 'C'
}];

const sectionNavigationListStyling = css({
  '& > li': {
    backgroundColor: COLORS.GREY_BACKGROUND,
    color: COLORS.PRIMARY,
    borderWidth: 0
  }
});

const roErrorTitle = css({ paddingLeft: '100px' });

export default class AssignHearings extends React.Component {

  // required to reset the RO Dropdown when moving from Viewing and Assigning.
  componentWillMount = () => {
    this.props.onRegionalOfficeChange('');
  }

  onSelectedHearingDayChange = (hearingDay) => () => {
    this.props.onSelectedHearingDayChange(hearingDay);
  };

  roomInfo = (hearingDay) => {
    let room = hearingDay.roomInfo;

    if (hearingDay.regionalOffice === 'St. Petersburg, FL') {
      return room;
    } else if (hearingDay.regionalOffice === 'Winston-Salem, NC') {
      return room;
    }

    return room = '';

  }

  formatAvailableHearingDays = () => {
    return <div className="usa-width-one-fourth">
      <h3>Hearings to Schedule</h3>
      <h4>Available Hearing Days</h4>
      <ul className="usa-sidenav-list" {...sectionNavigationListStyling}>
        {Object.values(this.props.upcomingHearingDays).slice(0, 9).
          map((hearingDay) => {
            const { selectedHearingDay } = this.props;
            const dateSelected = selectedHearingDay &&
            (selectedHearingDay.hearingDate === hearingDay.hearingDate &&
               selectedHearingDay.roomInfo === hearingDay.roomInfo);
            const buttonColorSelected = css({
              backgroundColor: COLORS.GREY_DARK,
              color: COLORS.WHITE,
              borderRadius: '0.1rem 0.1rem 0 0',
              '&:hover': {
                backgroundColor: COLORS.GREY_DARK,
                color: COLORS.WHITE
              }
            });

            const styling = dateSelected ? buttonColorSelected : '';

            return <li key={hearingDay.id} >
              <Button
                styling={styling}
                onClick={this.onSelectedHearingDayChange(hearingDay)}
                linkStyling
              >
                {`${moment(hearingDay.hearingDate).format('ddd M/DD/YYYY')}
                ${this.roomInfo(hearingDay)}`}
              </Button>
            </li>;
          })}
      </ul>
    </div>;
  };

  veteranTypeColor = (docketType) => {

    if (docketType === 'CAVC') {
      return <span {...colorAOD}>CAVC</span>;
    } else if (docketType === 'AOD') {
      return <span {...colorAOD}>AOD</span>;
    }

    return docketType;
  }

    getHearingTime = (date, regionalOfficeTimezone) => {
      return <div>
        {getTime(date)} /<br />{getTimeInDifferentTimeZone(date, regionalOfficeTimezone)}
      </div>;
    };

  appellantName = (hearingDay) => {
    if (hearingDay.appellantFirstName && hearingDay.appellantLastName) {
      return `${hearingDay.appellantFirstName} ${hearingDay.appellantLastName} | ${hearingDay.id}`;
    }

    return `${hearingDay.id}`;

  }

  tableAssignHearingsRows = (veterans) => {
    return _.map(veterans, (veteran) => ({
      caseDetails: this.appellantName(veteran),
      type: this.veteranTypeColor(veteran.type),
      docketNumber: veteran.docketNumber,
      location: this.props.selectedRegionalOffice.value === 'C' ? 'Washington DC' : veteran.location,
      time: null
    }));
  };

  tableScheduledHearingsRows = (hearings) => {
    return _.map(hearings, (hearing) => ({
      caseDetails: `${hearing.appellantMiFormatted} | ${hearing.vbmsId}`,
      type: this.veteranTypeColor(hearing.appealType),
      docketNumber: hearing.docketNumber,
      location: hearing.requestType === 'Video' ? hearing.regionalOfficeName : 'Washington DC',
      time: this.getHearingTime(hearing.date, hearing.regionalOfficeTimezone)
    }));
  };

  roNotAssignedTitle = () => {
    if (this.props.selectedRegionalOffice.label) {
      return <span>The {this.props.selectedRegionalOffice.label} Regional Office has not been <br />
        <span {...roErrorTitle}>assigned any hearing days</span></span>;
    }
  }

  roNotAssignedTitleError = () => {
    if (this.props.selectedHearingDay && this.props.selectedHearingDay.hearings &&
          _.isEmpty(this.props.selectedHearingDay.hearings)) {
      return <div>
        <AssignStatusMessage
          message="Please verify that this RO has been assigned hearings"
          title={this.roNotAssignedTitle()}
        />
      </div>;
    }
  }

  veteransReadyForHearing = () => {

    const tabWindowColumns = [
      {
        header: 'Case details',
        align: 'left',
        valueName: 'caseDetails'
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
        header: 'Location',
        align: 'left',
        valueName: 'location'
      },
      {
        header: 'Time',
        align: 'left',
        valueName: 'time'
      }
    ];

    const getHearingsTab = (selectedHearingDay) => {
      if (selectedHearingDay) {
        return <Table
            columns={tabWindowColumns}
            rowObjects={this.tableRows(this.props.selectedHearingDay.hearings)}
            summary="scheduled-hearings-table"
        />;
      }
    };

    const selectedHearingDay = this.props.selectedHearingDay;

    const availableSlots = selectedHearingDay.totalSlots - Object.keys(selectedHearingDay.hearings).length;

    return <div className="usa-width-three-fourths">
      <h1>
        {`${moment(selectedHearingDay.hearingDate).format('ddd M/DD/YYYY')}
       ${this.roomInfo(selectedHearingDay)} (${availableSlots} slots remaining)`}
      </h1>
      <TabWindow
        name="scheduledHearings-tabwindow"
        tabs={[
          {
            label: 'Scheduled',
            page: <Table
              columns={tabWindowColumns}
              rowObjects={this.tableScheduledHearingsRows(this.props.selectedHearingDay.hearings)}
              summary="scheduled-hearings-table"
            />
          },
          {
            label: 'Assign Hearings',
            page: <Table
              columns={tabWindowColumns}
              rowObjects={this.tableAssignHearingsRows(this.props.veteransReadyForHearing)}
              summary="assign-hearings-table"
            />
          }
        ]}
      />
    </div>;
  };

  render() {
    return <AppSegment filledBackground>
      <h1>{COPY.HEARING_SCHEDULE_ASSIGN_HEARINGS_HEADER}</h1>
      <Link
        name="view-schedule"
        to="/schedule">
        {COPY.HEARING_SCHEDULE_ASSIGN_HEARINGS_VIEW_SCHEDULE_LINK}
      </Link>
      <RoSelectorDropdown
        onChange={this.props.onRegionalOfficeChange}
        value={this.props.selectedRegionalOffice}
        staticOptions={centralOfficeStaticEntry}
      />
      {this.props.upcomingHearingDays && this.formatAvailableHearingDays()}
      {this.props.upcomingHearingDays &&
        this.props.veteransReadyForHearing &&
        this.props.selectedHearingDay &&
        this.veteransReadyForHearing()}
    </AppSegment>;
  }
}

AssignHearings.propTypes = {
  regionalOffices: PropTypes.object,
  onRegionalOfficeChange: PropTypes.func,
  selectedRegionalOffice: PropTypes.object,
  upcomingHearingDays: PropTypes.object,
  onSelectedHearingDayChange: PropTypes.func,
  selectedHearingDay: PropTypes.object,
  veteransReadyForHearing: PropTypes.object
};
