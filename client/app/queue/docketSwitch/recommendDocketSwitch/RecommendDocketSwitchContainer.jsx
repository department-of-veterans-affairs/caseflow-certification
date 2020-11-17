import React, { useEffect, useMemo } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { useHistory, useParams } from 'react-router';
import { fetchJudges } from '../../QueueActions';

import { appealWithDetailSelector } from '../../selectors';
import DISPOSITIONS from '../../../../constants/DOCKET_SWITCH';
import { createDocketSwitchRulingTask } from './recommendDocketSwitchSlice';
import { RecommendDocketSwitchForm } from './RecommendDocketSwitchForm';
import {
  DOCKET_SWITCH_REQUEST_TITLE,
  DOCKET_SWITCH_REQUEST_MESSAGE,
} from '../../../../COPY';

import { sprintf } from 'sprintf-js';
import { showSuccessMessage } from '../../uiReducer/uiActions';

// This takes form data and generates Markdown-formatted text to be saved as task instructions
export const formatDocketSwitchRecommendation = ({
  summary,
  timely,
  disposition,
  hyperlink,
}) => {
  const parts = [];

  const timelyCaps = timely[0].toUpperCase() + timely.substring(1);

  parts.push(`**Summary:** ${summary}`);
  parts.push(`**Is this a timely request:** ${timelyCaps}`);
  parts.push(`**Recommendation:** ${DISPOSITIONS[disposition].displayText}`);
  parts.push(`**Draft letter:** ${hyperlink}`);

  // Separate each chunk by two line breaks
  return parts.join('  \n  \n');
};

export const RecommendDocketSwitchContainer = () => {
  const { appealId, taskId } = useParams();
  const { goBack, push } = useHistory();
  const dispatch = useDispatch();

  const appeal = useSelector((state) =>
    appealWithDetailSelector(state, { appealId })
  );

  const judges = useSelector((state) => state.queue.judges);
  const judgeOptions = useMemo(
    () =>
      Object.values(judges).map(({ id: value, display_name: label }) => ({
        label,
        value,
      })),
    [judges]
  );

  // We want to default the judge selection to the VLJ currently assigned to the case, if exists
  const defaultJudgeId = useMemo(() => {
    // eslint-disable-next-line no-undefined
    return appeal.assignedJudge?.id ?? undefined;
  }, [judges, appeal]);

  // eslint-disable-next-line no-console
  const handleSubmit = async (formData) => {

    const instructions = formatDocketSwitchRecommendation({ ...formData });
    const newTask = {
      parent_id: taskId,
      type: 'DocketSwitchRulingTask',
      external_id: appeal.externalId,
      instructions,
      assigned_to_id: formData.judge.value,
      assigned_to_type: 'User',
    };

    const data = {
      tasks: [newTask],
    };

    const successMessage = {
      title: sprintf(DOCKET_SWITCH_REQUEST_TITLE, appeal.appellantFullName, formData.judge.label),
      detail: DOCKET_SWITCH_REQUEST_MESSAGE,
    };

    try {
      await dispatch(createDocketSwitchRulingTask(data));

      dispatch(showSuccessMessage(successMessage));
      push('/queue');
    } catch (error) {
      // Perhaps show an alert that indicates error, advise trying again...?
      console.error('Error saving task', error);
    }
  };

  useEffect(() => {
    if (!judgeOptions.length) {
      dispatch(fetchJudges());
    }
  });

  return (
    <RecommendDocketSwitchForm
      onCancel={goBack}
      onSubmit={handleSubmit}
      judgeOptions={judgeOptions}
      defaultJudgeId={defaultJudgeId}
      appellantName={appeal.appellantFullName}
    />
  );
};
