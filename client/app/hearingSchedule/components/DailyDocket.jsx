import React from 'react';
import PropTypes from 'prop-types';
import moment from 'moment';
import { css } from 'glamor';
import _ from 'lodash';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import Table from '../../components/Table';
import RadioField from '../../components/RadioField';
import SearchableDropdown from '../../components/SearchableDropdown';
import TextareaField from '../../components/TextareaField';

const tableRowStyling = css({
  '& > tr:nth-child(even) > td': { borderTop: 'none' },
  '& > tr:nth-child(odd) > td': { borderBottom: 'none' },
  '& > tr > td': {
    verticalAlign: 'top',
  },
  '& > tr': {
    borderBottom: 'none',
    '& > td:nth-child(1)': { width: '2%' },
    '& > td:nth-child(2)': { width: '10%' },
    '& > td:nth-child(3)': { width: '10%' },
    '& > td:nth-child(4)': { width: '10%' },
    '& > td:nth-child(5)': { backgroundColor: '#f1f1f1',
      width: '20%' },
    '& > td:nth-child(6)': { backgroundColor: '#f1f1f1',
      width: '23%' },
    '& > td:nth-child(7)': { backgroundColor: '#f1f1f1',
      width: '23%' } }

  // },
  // '& > tr:nth-child(even)': {
  //     borderBottom: 'none',
  //     '& > td:nth-child(1)': { width: '2%' },
  //     '& > td:nth-child(2)': { width: '20%' },
  //     '& > td:nth-child(3)': { width: '10%' },
  //     '& > td:nth-child(4)': { backgroundColor: '#f1f1f1',
  //         width: '20%' },
  //     '& > td:nth-child(5)': { backgroundColor: '#f1f1f1',
  //         width: '23%' },
  //     '& > td:nth-child(6)': { backgroundColor: '#f1f1f1',
  //         width: '23%' }
  // }
});

const noMarginStyling = css({
  marginRight: '-40px',
  marginLeft: '-40px'
});

export default class DailyDocket extends React.Component {

  getAppellantInformation = (hearing) => {
    return <div><b>{hearing.appellantName} ({hearing.vbmsId})</b> <br />
      {hearing.appellantAddress} <br />
      {hearing.appellantCity}, {hearing.appellantState} {hearing.appellantZipCode}
    </div>;
  };

  getHearingTime = (hearing) => {
    return <div>{hearing.hearingTime} <br />
      {hearing.hearingLocation}
    </div>
  };

  getDispositionDropdown = (hearing) => {
    return <SearchableDropdown
      name="Disposition"
      placeholder="Select disposition"
      options={[
        {
          label: 'Held',
          value: 'held'
        }
      ]}
      value={hearing.disposition}
      onChange={() => {}}
    />;
  };

  getHearingLocationDropdown = (hearing) => {
    return <SearchableDropdown
      name="Hearing Location"
      options={[
        {
          label: 'Houston, TX',
          value: 'Houston, TX'
        }
      ]}
      value={hearing.hearingLocation}
      onChange={() => {}}
    />
  };

  getHearingDayDropdown = (hearing) => {
    return <div><SearchableDropdown
      name="Hearing Day"
      options={[
        {
          label: '2018-10-13',
          value: '2018-10-13'
        }
      ]}
      value={hearing.hearingDate}
      onChange={() => {}}
    />
    <RadioField
      name="Hearing Time"
      options={[
        {
          displayText: '8:30',
          value: '8:30'
        },
        {
          displayText: '1:30',
          value: '1:30'
        }
      ]}
      onChange={() => {}}
      hideLabel
    />
    </div>;
  };

  render() {
    const dailyDocketColumns = [
      {
        header: '',
        align: 'left',
        valueName: 'number'
      },
      {
        header: 'Appellant/Veteran ID',
        align: 'left',
        valueName: 'appellantInformation'
      },
      {
        header: 'Time/RO(s)',
        align: 'left',
        valueName: 'hearingTime'
      },
      {
        header: 'Representative',
        align: 'left',
        valueName: 'representative'
      },
      {
        header: 'Actions',
        align: 'left',
        valueName: 'hearingLocation'
      },
      {
        header: '',
        align: 'left',
        valueName: 'hearingDay'
      },
      {
        header: '',
        align: 'left',
        valueName: 'disposition'
      }
    ];

    // const dailyDocketRows = _.map(this.props.hearings, (hearing) => ({
    //   number: '1.',
    //   appellantInformation: this.getAppellantInformation(hearing),
    //   hearingTime: this.getHearingTime(hearing),
    //   representative: <div>{hearing.representative} <br /> {hearing.representativeName}</div>,
    //   hearingLocation: this.getHearingLocationDropdown(hearing),
    //   hearingDay: this.getHearingDayDropdown(hearing),
    //   disposition: this.getDispositionDropdown(hearing)
    // }));

    const hearing = this.props.hearings[123];

    const dailyDocketRows = [
      {
        number: '1.',
        appellantInformation: this.getAppellantInformation(hearing),
        hearingTime: this.getHearingTime(hearing),
        representative: <div>{hearing.representative} <br /> {hearing.representativeName}</div>,
        hearingLocation: this.getHearingLocationDropdown(hearing),
        hearingDay: this.getHearingDayDropdown(hearing),
        disposition: this.getDispositionDropdown(hearing)
      },
      {
        appellantInformation: <div>{hearing.issueCount} issues</div>,
        hearingTime: "This is a text area field!"
      }
    ];

    return <AppSegment filledBackground>
      <div className="cf-push-left">
        <h1>Daily Docket ({moment(this.props.hearingDate).format('ddd M/DD/YYYY')})</h1> <br />
        <Link to="/schedule">&lt; Back to schedule</Link>
      </div>
      <span className="cf-push-right">
        VLJ: {this.props.vlj} <br />
        Coordinator: {this.props.coordinator} <br />
        Hearing type: {this.props.hearingType}
      </span>
      <div {...noMarginStyling}>
        <Table
          columns={dailyDocketColumns}
          rowObjects={dailyDocketRows}
          summary="dailyDocket"
          bodyStyling={tableRowStyling}
        />
      </div>
    </AppSegment>;
  }
}

DailyDocket.propTypes = {
  vlj: PropTypes.string,
  coordinator: PropTypes.string,
  hearingType: PropTypes.string,
  hearingDate: PropTypes.string,
  hearings: PropTypes.object
};
