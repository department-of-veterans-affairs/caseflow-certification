import React from 'react';
import classNames from 'classnames';
import PropTypes from 'prop-types';

import { marginTop } from '../details/style';
import { VirtualHearingEmail } from './Emails';
import { Timezone } from './Timezone';
import { HelperText } from './HelperText';
import COPY from '../../../../COPY';

export const VirtualHearingFields = ({
  errors,
  appellantTitle,
  requestType,
  defaultAppellantTz,
  defaultRepresentativeTz,
  virtualHearing,
  readOnly,
  update,
  time
}) => {
  const central = requestType !== 'Video';

  return central ? (
    <React.Fragment>
      <h3>{appellantTitle}</h3>
      <div id="email-section" className="usa-grid">
        <div className="usa-width-one-third">
          <Timezone
            required
            value={virtualHearing?.appellantTz || defaultAppellantTz}
            onChange={(appellantTz) => update('virtualHearing', { appellantTz })}
            readOnly={readOnly}
            time={time}
            name="appellantTz"
            label={`${appellantTitle} Timezone`}
          />
          <HelperText label={COPY.VIRTUAL_HEARING_TIMEZONE_HELPER_TEXT} />
        </div>
        <div className="usa-width-one-third">
          <VirtualHearingEmail
            required
            disabled={readOnly}
            label={`${appellantTitle} Email`}
            emailType="appellantEmail"
            email={virtualHearing?.appellantEmail}
            error={errors?.appellantEmail}
            update={update}
          />
        </div>
      </div>
      <div className="cf-help-divider" />
      <h3>Power of Attorney</h3>
      <div className={classNames('usa-grid', { [marginTop(30)]: true })}>
        <div className="usa-width-one-third">
          <Timezone
            errorMessage={errors?.representativeTz}
            required={virtualHearing?.representativeEmail}
            value={virtualHearing?.representativeTz || defaultRepresentativeTz}
            onChange={(representativeTz) => update('virtualHearing', { representativeTz })}
            readOnly={readOnly || !virtualHearing?.representativeEmail}
            time={time}
            name="representativeTz"
            label="POA/Representative Timezone"
          />
          <HelperText label={COPY.VIRTUAL_HEARING_TIMEZONE_HELPER_TEXT} />
        </div>
        <div className="usa-width-one-third">
          <VirtualHearingEmail
            disabled={readOnly}
            label="POA/Representative Email"
            emailType="representativeEmail"
            email={virtualHearing?.representativeEmail}
            error={errors?.representativeEmail}
            update={update}
          />
        </div>
      </div>
    </React.Fragment>
  ) : (
    <div id="email-section" className="usa-grid">
      <div className="usa-width-one-third">
        <VirtualHearingEmail
          required
          disabled={readOnly}
          label={`${appellantTitle} Email`}
          emailType="appellantEmail"
          email={virtualHearing?.appellantEmail}
          error={errors?.appellantEmail}
          update={update}
        />
      </div>
      <div className="usa-width-one-third">
        <VirtualHearingEmail
          disabled={readOnly}
          label="POA/Representative Email"
          emailType="representativeEmail"
          email={virtualHearing?.representativeEmail}
          error={errors?.representativeEmail}
          update={update}
        />
      </div>
    </div>
  );
};

VirtualHearingFields.propTypes = {
  requestType: PropTypes.string.isRequired,
  time: PropTypes.string.isRequired,
  appellantTitle: PropTypes.string.isRequired,
  readOnly: PropTypes.bool,
  update: PropTypes.func,
  virtualHearing: PropTypes.object,
  errors: PropTypes.object,
  defaultAppellantTz: PropTypes.string,
  defaultRepresentativeTz: PropTypes.string,
};
