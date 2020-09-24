import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import PropTypes from 'prop-types';
import React, { useState } from 'react';

import { HearingTypeConversionForm } from './HearingTypeConversionForm';
import { appealWithDetailSelector, taskById } from '../../queue/selectors';
import {
  showErrorMessage,
  showSuccessMessage
} from '../../queue/uiReducer/uiActions';
import ApiUtil from '../../util/ApiUtil';
import COPY from '../../../COPY.json';
import HEARING_REQUEST_TYPES from
  '../../../constants/HEARING_REQUEST_TYPES';
import TASK_STATUSES from '../../../constants/TASK_STATUSES.json';

const HearingTypeConversion = ({
  appeal,
  history,
  showErrorMessage,
  showSuccessMessage,
  task,
  type
}) => {
  // Create and manage the loading state
  const [loading, setLoading] = useState(false);

  const getSuccessMsg = () => {
    const title = sprintf(COPY.CONVERT_HEARING_TYPE_SUCCESS, appeal?.appellantFullName, type);
    const detail = sprintf(
      COPY.CONVERT_HEARING_TYPE_SUCCESS_DETAIL,
      appeal?.closestRegionalOffice || COPY.CONVERT_HEARING_TYPE_DEFAULT_REGIONAL_OFFICE_TEXT
    );

    return { title, detail };
  };

  const submit = async () => {
    try {
      const changedRequestType = type === 'Virtual' ? HEARING_REQUEST_TYPES.virtual : HEARING_REQUEST_TYPES.video;
      const data = {
        task: {
          status: TASK_STATUSES.completed,
          business_payloads: {
            values: {
              changed_request_type: changedRequestType
            }
          }
        }
      };

      setLoading(true);

      await ApiUtil.patch(`/tasks/${task.taskId}`, { data });      
    } catch (err) {
      // What could this be?
      return;
    } finally {
      // Show that the action went through before redirecting the user back to the
      // appeals page.
      setLoading(false);
    }

    showSuccessMessage(getSuccessMsg());

    history.push(`/queue/appeals/${appeal.externalId}`);
  };

  return (
    <HearingTypeConversionForm
      appeal={appeal}
      history={history}
      isLoading={loading}
      onCancel={() => history.goBack()}
      onSubmit={submit}
      task={task}
      type={type}
    />
  );
};

HearingTypeConversion.propTypes = {
  appeal: PropTypes.object,
  appealId: PropTypes.string,
  showErrorMessage: PropTypes.func,
  showSuccessMessage: PropTypes.func,
  task: PropTypes.object,
  taskId: PropTypes.string,
  type: PropTypes.oneOf(['Virtual']),
  // Router inherited props
  history: PropTypes.object
};

const mapStateToProps = (state, ownProps) => ({
  appeal: appealWithDetailSelector(state, ownProps),
  task: taskById(state, { taskId: ownProps.taskId })
});

const mapDispatchToProps = (dispatch) =>
  bindActionCreators(
    {
      showErrorMessage,
      showSuccessMessage
    },
    dispatch
  );

export default withRouter(
  connect(
    mapStateToProps,
    mapDispatchToProps
  )(HearingTypeConversion)
);
