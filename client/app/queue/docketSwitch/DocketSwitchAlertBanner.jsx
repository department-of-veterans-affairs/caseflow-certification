import React from 'react';
import PropTypes from 'prop-types';
import COPY from 'app/../COPY';
import Alert from 'app/components/Alert';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

const DocketSwitchAlertBanner = ({ appeal }) => {
  // This variable gives us the Docket Switch object on both the old and new appeal case details page
  const docketSwitch = appeal.docketSwitch ? appeal.docketSwitch : appeal.switchedDocket;

  const fullGrantSuccessMessage = <div>
    {COPY.DOCKET_SWITCH_FULL_GRANTED_LABEL}
    <Link
      name="appeal-stream"
      to={`${docketSwitch.new_appeal_uuid}`}>
      switched appeal stream.</Link>
  </div>;

  const partialGrantOldDocketSuccessMessage = <div>
    {COPY.DOCKET_SWITCH_PARTIAL_GRANTED_LABEL_OLD_DOCKET}
    <Link
      name="appeal-stream"
      to={`${docketSwitch.new_appeal_uuid}`}>
      switched appeal stream.</Link>
  </div>;

  const partialGrantNewDocketSuccessMessage = <div>
    {COPY.DOCKET_SWITCH_PARTIAL_GRANTED_LABEL_NEW_DOCKET}
    <Link
      name="appeal-stream"
      to={`${docketSwitch.old_appeal_uuid}`}>
      other appeal stream.</Link>
  </div>;

  debugger

  if (docketSwitch.disposition === 'granted') {
    return (
      <div>
        <Alert
          message={fullGrantSuccessMessage}
          title={COPY.DOCKET_SWITCH_FULL_GRANTED_TITLE}
          type="info"
        />
        <br />
      </div>
    );
  }

  return (
    <div>
      <Alert
        message={appeal.docketSwitch ? partialGrantNewDocketSuccessMessage : partialGrantOldDocketSuccessMessage}
        title={appeal.docketSwitch ?
          COPY.DOCKET_SWITCH_PARTIAL_GRANTED_TITLE_NEW_DOCKET :
          COPY.DOCKET_SWITCH_PARTIAL_GRANTED_TITLE_OLD_DOCKET
        }
        type="info"
      />
      <br />
    </div>
  );
};

DocketSwitchAlertBanner.propTypes = {
  appeal: PropTypes.object.isRequired
};

export default DocketSwitchAlertBanner;

