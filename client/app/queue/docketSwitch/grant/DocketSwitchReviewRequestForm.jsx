import React, { useMemo, useState } from 'react';
import PropTypes from 'prop-types';
import { useForm, Controller } from 'react-hook-form';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import { CheckoutButtons } from './CheckoutButtons';
import {
  DOCKET_SWITCH_GRANTED_REQUEST_LABEL,
  DOCKET_SWITCH_GRANTED_REQUEST_INSTRUCTIONS
} from 'app/../COPY';
import { sprintf } from 'sprintf-js';
import { yupResolver } from '@hookform/resolvers';
import * as yup from 'yup';
import { css } from 'glamor';
import DateSelector from 'app/components/DateSelector';
import RadioField from 'app/components/RadioField';
import CheckboxGroup from 'app/components/CheckboxGroup';
import DISPOSITIONS from 'constants/DOCKET_SWITCH';

const schema = yup.object().shape({
  receiptDate: yup.date().required(),
  disposition: yup.
    mixed().
    oneOf(Object.keys(DISPOSITIONS)).
    required(),
  docketType: yup.string().required(),
  // Validation of issueIds is conditional upon the selected disposition
  issueIds: yup.array(yup.string()).when('disposition', {
    is: 'partially_granted',
    then: yup.array().min(1),
    otherwise: yup.array().min(0),
  }),

});

const docketTypeRadioOptions = [
  { value: 'direct_review',
    displayText: 'Direct Review' },
  { value: 'evidence_submission',
    displayText: 'Evidence Submission' },
  { value: 'hearing',
    displayText: 'Hearing' }
];

export const DocketSwitchReviewRequestForm = ({
  onSubmit,
  onCancel,
  appellantName,
  issues
}) => {
  const { register, handleSubmit, control, formState, watch } = useForm({
    resolver: yupResolver(schema),
    mode: 'onChange',
  });
  const sectionStyle = css({ marginBottom: '24px' });

  const issueOptions = useMemo(() =>
    issues && issues.map((issue, idx) => ({
      id: issue.id.toString(),
      label: `${idx + 1}. ${issue.description}`,
    })), [issues]
  );

  const dispositionOptions = useMemo(() =>
    Object.values(DISPOSITIONS).filter((disposition) => disposition.value !== 'denied'), []);

  const watchDisposition = watch('disposition');

  const [issue, setIssues] = useState({});

  // We have to do a bit of manual manipulation for issue IDs due to nature of CheckboxGroup
  const handleIssueChange = (evt) => {
    const newIssues = { ...issue, [evt.target.name]: evt.target.checked };

    setIssues(newIssues);

    // Form wants to track only the selected issue IDs
    return Object.keys(newIssues).filter((key) => newIssues[key]);
  };

  return (
    <form
      className="docket-switch-granted-request"
      onSubmit={handleSubmit(onSubmit)}
      aria-label="Grant Docket Switch Request"
    >
      <AppSegment filledBackground>
        <h1>{sprintf(DOCKET_SWITCH_GRANTED_REQUEST_LABEL, appellantName)}</h1>
        <div {...sectionStyle}>{DOCKET_SWITCH_GRANTED_REQUEST_INSTRUCTIONS}</div>

        <DateSelector
          inputRef={register}
          type="date"
          name="receiptDate"
          label="What is the Receipt Date of the docket switch request?"
          strongLabel
        />

        <RadioField
          name="disposition"
          label="How are you proceeding with this request to switch dockets?"
          options={dispositionOptions}
          inputRef={register}
          strongLabel
          vertical
        />

        { watchDisposition === 'partially_granted' && (
          <Controller
            name="issueIds"
            control={control}
            defaultValue={[]}
            render={({ onChange: onCheckChange }) => {
              return (
                <CheckboxGroup
                  name="issues"
                  label="Select the issue(s) that are switching dockets:"
                  strongLabel
                  options={issueOptions}
                  onChange={(event) => onCheckChange(handleIssueChange(event))}
                />
              );
            }}
          />
        )}

        {watchDisposition &&
         <RadioField
           name="docketType"
           label="Which docket will the issue(s) be switched to?"
           options={docketTypeRadioOptions}
           inputRef={register}
           strongLabel
           vertical
         />
        }

      </AppSegment>
      <div className="controls cf-app-segment">
        <CheckoutButtons
          disabled={!formState.isValid}
          onCancel={onCancel}
          onSubmit={handleSubmit(onSubmit)}
        />
      </div>
    </form>
  );
};

DocketSwitchReviewRequestForm.propTypes = {
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func,
  appellantName: PropTypes.string.isRequired,
  issues: PropTypes.array
};