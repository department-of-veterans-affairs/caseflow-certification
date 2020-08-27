import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { css } from 'glamor';
import { isEmpty, isUndefined, get } from 'lodash';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import PropTypes from 'prop-types';
import React, { useState, useContext, useEffect } from 'react';

import { DetailsHeader } from './details/DetailsHeader';
import { HearingConversion } from './HearingConversion';
import {
  HearingsFormContext,
  updateHearingDispatcher,
  RESET_HEARING,
  RESET_VIRTUAL_HEARING
} from '../contexts/HearingsFormContext';
import { HearingsUserContext } from '../contexts/HearingsUserContext';
import { deepDiff, pollVirtualHearingData, getChanges, getAppellantTitleForHearing } from '../utils';
import { inputFix } from './details/style';
import {
  onReceiveAlerts,
  onReceiveTransitioningAlert,
  transitionAlert,
  clearAlerts
} from '../../components/common/actions';
import Alert from '../../components/Alert';
import ApiUtil from '../../util/ApiUtil';
import Button from '../../components/Button';
import DetailsForm from './details/DetailsForm';
import UserAlerts from '../../components/UserAlerts';
import VirtualHearingModal from './VirtualHearingModal';

/**
 * Hearing Details Component
 * @param {Object} props -- React props inherited from client/app/hearings/containers/DetailsContainer.jsx
 * @component
 */
const HearingDetails = (props) => {
  // Map the state and dispatch to relevant names
  const { state: { initialHearing, hearing, formsUpdated }, dispatch } = useContext(HearingsFormContext);

  // Pull out feature flag
  const { userUseFullPageVideoToVirtual } = useContext(HearingsUserContext);

  // Create the update hearing dispatcher
  const updateHearing = updateHearingDispatcher(hearing, dispatch);

  // Pull out the inherited state to handle actions
  const { saveHearing, goBack, disabled } = props;

  // Determine whether this is a legacy hearing
  const isLegacy = hearing?.docketName !== 'hearing';

  // Establish the state of the hearing details
  const [converting, convertHearing] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [virtualHearingErrors, setVirtualHearingErrors] = useState({});
  const [virtualHearingModalOpen, setVirtualHearingModalOpen] = useState(false);
  const [virtualHearingModalType, setVirtualHearingModalType] = useState(null);
  const [shouldStartPolling, setShouldStartPolling] = useState(null);

  // Method to reset the state
  const reset = () => {
    // Reset the state
    setVirtualHearingErrors({});
    convertHearing('');
    setLoading(false);
    setError(false);

    // Focus the top of the page
    window.scrollTo(0, 0);
  };

  // Create an effect to remove stale alerts on unmount
  useEffect(() => () => props.clearAlerts(), []);

  const openVirtualHearingModal = ({ type }) => {
    setVirtualHearingModalOpen(true);
    setVirtualHearingModalType(type);
  };

  const closeVirtualHearingModal = () => setVirtualHearingModalOpen(false);

  const getEditedEmails = () => {
    const changes = deepDiff(
      initialHearing.virtualHearing,
      hearing.virtualHearing || {}
    );

    return {
      appellantEmailEdited: !isUndefined(changes.appellantEmail),
      representativeEmailEdited: !isUndefined(changes.representativeEmail),
      representativeTzEdited: !isUndefined(changes.representativeTz),
      appellantTzEdited: !isUndefined(changes.appellantTz)
    };
  };

  const processAlerts = (alerts) => {
    alerts.forEach((alert) => {
      if ('hearing' in alert) {
        props.onReceiveAlerts(alert.hearing);
      } else if ('virtual_hearing' in alert && !isEmpty(alert.virtual_hearing)) {
        props.onReceiveTransitioningAlert(alert.virtual_hearing, 'virtualHearing');
        setShouldStartPolling(true);
      }
    });
  };

  const submit = async (editedEmails) => {
    try {
      // Determine the current state and whether to error
      const virtual = hearing.isVirtual || hearing.wasVirtual || converting;
      const noAppellantEmail = !hearing.virtualHearing?.appellantEmail;
      const noRepTimezone = !hearing.virtualHearing?.representativeTz && hearing.virtualHearing?.representativeEmail;
      const noAppellantTimezone = !hearing.virtualHearing?.appellantTz;
      const emailUpdated = (
        editedEmails?.appellantEmailEdited ||
        (editedEmails?.representativeEmailEdited && hearing.virtualHearing?.representativeEmail)
      );
      const timezoneUpdated = editedEmails?.representativeTzEdited || editedEmails?.appellantTzEdited;
      const errors = noAppellantEmail ||
                    ((noAppellantTimezone || noRepTimezone) && hearing.readableRequestType !== 'Video');

      if (virtual && errors) {
        // Set the Virtual Hearing errors
        setVirtualHearingErrors({
          [noAppellantEmail && 'appellantEmail']: `${getAppellantTitleForHearing(hearing)} email is required`,
          [noRepTimezone && 'representativeTz']: 'Timezone is required to send email notifications.',
          [noAppellantTimezone && 'appellantTz']: 'Timezone is required to send email notifications.'
        });

        // Focus to the error
        return document.getElementById('email-section').scrollIntoView();
      } else if ((emailUpdated || timezoneUpdated) && !converting) {
        return openVirtualHearingModal({ type: 'change_email_or_timezone' });
      }

      // Only send updated properties
      const { virtualHearing, transcription, ...hearingChanges } = getChanges(
        initialHearing,
        hearing
      );

      // Put the UI into a loading state
      setLoading(true);

      // Save the hearing
      const response = await saveHearing({
        hearing: {
          ...(hearingChanges || {}),
          transcription_attributes: {
            // Always send full transcription details because a new record is created each update
            ...(transcription ? hearing.transcription : {}),
          },
          virtual_hearing_attributes: {
            ...(virtualHearing || {}),
          },
        },
      });
      const hearingResp = ApiUtil.convertToCamelCase(response.body?.data);

      const alerts = response.body?.alerts;

      if (alerts) {
        processAlerts(alerts);
      }

      // Reset the state
      reset();
      dispatch({ type: RESET_HEARING, payload: hearingResp });
    } catch (respError) {
      const code = get(respError, 'response.body.errors[0].code') || '';

      // Retrieve the error message from the body
      const msg = respError?.response?.body?.errors.length > 0 && respError?.response?.body?.errors[0]?.message;

      // Set the state with the error
      setLoading(false);

      // email validations should be thrown inline
      if (code === 1002) {
        // API errors from the server need to be bubbled up to the VirtualHearingModal so it can
        // update the email components with the validation error messages.
        const changingFromVideoToVirtualWithModalFlow = (
          hearing?.readableRequestType === 'Video' &&
          !hearing.isVirtual &&
          !userUseFullPageVideoToVirtual
        );

        if (changingFromVideoToVirtualWithModalFlow) {
          // 1002 is returned with an invalid email. rethrow respError, then re-catch it in VirtualHearingModal
          throw respError;
        } else {
          // Remove the validation string from th error
          const messages = msg.split(':')[1];

          // Set inline errors for hearing conversion page
          const errors = messages.split(',').reduce((list, message) => ({
            ...list,
            [(/Representative/).test(message) ? 'representativeEmail' : 'appellantEmail']:
              message.replace('Appellant', getAppellantTitleForHearing(hearing))
          }), {});

          document.getElementById('email-section').scrollIntoView();

          setVirtualHearingErrors(errors);
        }
      } else {
        setError(msg);
      }
    }
  };

  const startPolling = () => {
    return pollVirtualHearingData(hearing?.externalId, (response) => {
      // response includes jobCompleted, aliasWithHost, guestPin, hostPin,
      // guestLink, and hostLink
      const resp = ApiUtil.convertToCamelCase(response);

      if (resp.virtualHearing.jobCompleted) {
        setShouldStartPolling(false);

        // Reset the state with the new details
        reset();
        dispatch({ type: RESET_VIRTUAL_HEARING, payload: resp });
        props.transitionAlert('virtualHearing');
      }

      // continue polling if return true (opposite of jobCompleted)
      return !resp.virtualHearing.jobCompleted;
    });
  };

  const editedEmails = getEditedEmails();
  const convertLabel = converting === 'change_to_virtual' ?
    'Convert to Virtual Hearing' : `Convert to ${hearing.readableRequestType} Hearing`;

  return (
    <React.Fragment>
      <UserAlerts />
      {error && (
        <div>
          <Alert
            type="error"
            title={error === '' ? 'There was an error updating the hearing' : error}
          />
        </div>
      )}
      {converting ? (
        <HearingConversion
          title={convertLabel}
          type={converting}
          update={updateHearing}
          hearing={hearing}
          scheduledFor={hearing?.scheduledFor}
          errors={virtualHearingErrors}
        />
      ) : (
        <AppSegment filledBackground>
          <div {...inputFix}>
            <DetailsHeader
              aod={hearing?.aod}
              disposition={hearing?.disposition}
              docketName={hearing?.docketName}
              docketNumber={hearing?.docketNumber}
              isVirtual={hearing?.isVirtual}
              hearingDayId={hearing?.hearingDayId}
              readableLocation={hearing?.readableLocation}
              readableRequestType={hearing?.readableRequestType}
              regionalOfficeName={hearing?.regionalOfficeName}
              scheduledFor={hearing?.scheduledFor}
              veteranFileNumber={hearing?.veteranFileNumber}
              veteranFirstName={hearing?.veteranFirstName}
              veteranLastName={hearing?.veteranLastName}
            />
            <DetailsForm
              hearing={hearing}
              initialHearing={initialHearing}
              update={updateHearing}
              convertHearing={convertHearing}
              errors={virtualHearingErrors}
              isLegacy={isLegacy}
              openVirtualHearingModal={openVirtualHearingModal}
              readOnly={disabled}
              requestType={hearing?.readableRequestType}
            />
            {shouldStartPolling && startPolling()}
          </div>
        </AppSegment>
      )}
      <div {...css({ overflow: 'hidden' })}>
        <Button
          name="Cancel"
          linkStyling
          onClick={converting ? () => reset(initialHearing) : goBack}
          styling={css({ float: 'left', paddingLeft: 0, paddingRight: 0 })}
        >
          Cancel
        </Button>
        <span {...css({ float: 'right' })}>
          <Button
            name="Save"
            disabled={!formsUpdated || disabled}
            loading={loading}
            className="usa-button"
            onClick={async () => await submit(editedEmails)}
          >
            {converting ? convertLabel : 'Save'}
          </Button>
        </span>
      </div>
      {virtualHearingModalOpen && (
        <VirtualHearingModal
          hearing={hearing}
          virtualHearing={hearing?.virtualHearing}
          update={updateHearing}
          submit={submit}
          closeModal={closeVirtualHearingModal}
          reset={() => reset(initialHearing)}
          type={virtualHearingModalType}
          {...editedEmails}
        />
      )}
    </React.Fragment>
  );
};

HearingDetails.propTypes = {
  saveHearing: PropTypes.func,
  goBack: PropTypes.func,
  disabled: PropTypes.bool,
  onReceiveAlerts: PropTypes.func,
  onReceiveTransitioningAlert: PropTypes.func,
  transitionAlert: PropTypes.func,
  clearAlerts: PropTypes.func,
};

const mapDispatchToProps = (dispatch) =>
  bindActionCreators({ clearAlerts, onReceiveAlerts, onReceiveTransitioningAlert, transitionAlert }, dispatch);

export default connect(
  null,
  mapDispatchToProps
)(HearingDetails);
