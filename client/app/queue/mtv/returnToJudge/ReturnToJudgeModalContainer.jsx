import React from 'react';
import { useHistory, useParams } from 'react-router';
import { ReturnToJudgeModal } from './ReturnToJudgeModal';
import { useDispatch } from 'react-redux';
import ApiUtil from '../../../util/ApiUtil';
import { showSuccessMessage } from '../../uiReducer/uiActions';

export const ReturnToJudgeModalContainer = () => {
  const { goBack, push } = useHistory();
  const { taskId } = useParams();
  const dispatch = useDispatch();

  const handleSubmit = async ({ instructions }) => {
    const url = '/post_decision_motions/return_to_judge';
    const data = ApiUtil.convertToSnakeCase({
      taskId,
      instructions
    });

    try {
      await ApiUtil.post(url, { data });

      dispatch(
        showSuccessMessage({
          title: 'Task Returned to Judge',
          detail: ' '
        })
      );

      push('/queue');
    } catch (error) {
      console.error('Error during returnToJudge', error);
    }
  };

  return <ReturnToJudgeModal onCancel={goBack} onSubmit={handleSubmit} />;
};
