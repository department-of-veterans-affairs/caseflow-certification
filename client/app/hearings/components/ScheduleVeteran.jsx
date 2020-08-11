/* eslint-disable camelcase */
import React from 'react';
import PropTypes from 'prop-types';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import {
  RegionalOfficeDropdown,
  AppealHearingLocationsDropdown,
  HearingDateDropdown
} from '../../components/DataDropdowns';
import { AddressLine } from './details/Address';
import { getAppellantTitleForHearing } from '../utils';
import { ReadOnly } from './details/ReadOnly';
import HearingTypeDropdown from './details/HearingTypeDropdown';
import { marginTop, virtualHearingModalStyles } from './details/style';
import { HearingTime } from './modalForms/HearingTime';
import Button from '../../components/Button';
import { css } from 'glamor';

export const ScheduleVeteran = ({ appeal, hearing, ...props }) => {
  const appellantTitle = getAppellantTitleForHearing(hearing);
  const ro = appeal.regionalOffice || hearing.regionalOffice;
  const location = appeal.hearingLocation || hearing.location;
  const header = `Schedule ${appellantTitle} for a Hearing`;

  return (
    <React.Fragment>
      <AppSegment filledBackground >
        <h1>{header}</h1>
        <div {...marginTop(45)} />
        <div className="usa-width-one-half">
          <HearingTypeDropdown requestType={hearing.readableRequestType} />
        </div>
        <div className="cf-help-divider usa-width-one-whole" />
        <div className="usa-width-one-half">
          <div {...virtualHearingModalStyles}>
            <ReadOnly spacing={0} label={`${appellantTitle} Address`} text={
              <AddressLine
                spacing={5}
                name={appeal?.veteranInfo?.veteran?.full_name}
                addressLine1={appeal?.veteranInfo?.veteran?.address?.address_line_1}
                addressState={appeal?.veteranInfo?.veteran?.address?.state}
                addressCity={appeal?.veteranInfo?.veteran?.address?.city}
                addressZip={appeal?.veteranInfo?.veteran?.address?.zip}
              />}
            />
          </div>
          <RegionalOfficeDropdown
            onChange={(regionalOffice) => props.onChange('appeal', { regionalOffice })}
            value={ro}
            validateValueOnMount
          />
          {ro && (
            <React.Fragment>
              <AppealHearingLocationsDropdown
                key={`hearingLocation__${ro}`}
                regionalOffice={ro}
                appealId={appeal.externalId}
                value={location}
                onChange={(hearingLocation) => props.onChange('appeal', { hearingLocation })}
              />
              <HearingDateDropdown
                key={`hearingDate__${ro}`}
                regionalOffice={ro}
                value={appeal.hearingDay}
                onChange={(hearingDay) => props.onChange('appeal', { hearingDay })}
              />
              <HearingTime
                vertical
                label="Hearing Time"
                enableZone
                onChange={(scheduledTimeString) => props.onChange('hearing', { scheduledTimeString })}
                value={hearing.scheduledTimeString}
              />
            </React.Fragment>
          )}
        </div>
      </AppSegment>
      <Button
        name="Cancel"
        linkStyling
        onClick={() => props.goBack()}
        styling={css({ float: 'left', paddingLeft: 0, paddingRight: 0 })}
      >
          Cancel
      </Button>
      <span {...css({ float: 'right' })}>
        <Button
          name="Schedule"
          loading={props.loading}
          className="usa-button"
          onClick={() => props.submit()}
        >
          Schedule
        </Button>
      </span>
    </React.Fragment>
  );
};

ScheduleVeteran.propTypes = {
  loading: PropTypes.bool,
  submit: PropTypes.func.isRequired,
  goBack: PropTypes.func.isRequired,
  onChange: PropTypes.func.isRequired,
  appeal: PropTypes.object,
  hearing: PropTypes.object
};

/* eslint-enable camelcase */
