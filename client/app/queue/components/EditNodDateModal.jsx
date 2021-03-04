import React, { useEffect, useState } from 'react';
import ReactMarkdown from 'react-markdown';
import { css } from 'glamor';
import PropTypes from 'prop-types';
import Modal from 'app/components/Modal';
import DateSelector from 'app/components/DateSelector';
import COPY from 'app/../COPY';
import { useDispatch, useSelector } from 'react-redux';
import { resetSuccessMessages, showSuccessMessage } from '../uiReducer/uiActions';
import { editAppeal, editNodDateUpdates } from '../QueueActions';
import ApiUtil from '../../util/ApiUtil';
import moment from 'moment';
import { sprintf } from 'sprintf-js';
import { formatDateStr, DateString } from '../../util/DateUtil';
import { appealWithDetailSelector } from '../selectors';
import Alert from 'app/components/Alert';
import SearchableDropdown from 'app/components/SearchableDropdown';
import { marginTop } from '../constants';

const alertStyling = css({
  marginBottom: '2em',
  '& .usa-alert-text': { lineHeight: '1' }
});

export const changeReasons = [
  { label: 'New Form/Information Received', value: 'new_info' },
  { label: 'Data Entry Error', value: 'entry_error' },
];

export const EditNodDateModalContainer = ({ onCancel, onSubmit, nodDate, appealId, reason }) => {
  const [showTimelinessError, setTimelinessError] = useState(false);
  const [issues, setIssues] = useState(null);
  const [reasonErrorMessage, setReasonErrorMessage] = useState(null);
  const [badDate, setBadDate] = useState(null);
  const [badReason, setBadReason] = useState(true);

  const dispatch = useDispatch();
  const appeal = useSelector((state) =>
    appealWithDetailSelector(state, { appealId })
  );

  useEffect(() => {
    dispatch(resetSuccessMessages());
  }, []);

  const handleSubmit = (receiptDate, changeReason) => {
    if (badReason) {
      setReasonErrorMessage('Required');
    }
    if (badReason || badDate) {
      return;
    }

    const alertInfo = {
      appellantName: (appeal.appellantFullName),
      nodDateStr: formatDateStr(nodDate, 'YYYY-MM-DD', 'MM/DD/YYYY'),
      receiptDateStr: formatDateStr(receiptDate, 'YYYY-MM-DD', 'MM/DD/YYYY')
    };

    const title = COPY.EDIT_NOD_DATE_SUCCESS_ALERT_TITLE;
    const detail = (sprintf(COPY.EDIT_NOD_DATE_SUCCESS_ALERT_MESSAGE, alertInfo));

    const successMessage = {
      title,
      detail,
    };
    const payload = {
      data: {
        receipt_date: receiptDate,
        change_reason: changeReason.value
      }
    };

    ApiUtil.patch(`/appeals/${appealId}/nod_date_update`, payload).then((data) => {
      dispatch(editAppeal(appealId, {
        nodDate: data.body.nodDate,
        docketNumber: data.body.docketNumber,
        reason: data.body.changeReason
      }));

      if (data.body.affectedIssues) {
        setIssues({ affectedIssues: data.body.affectedIssues, unaffectedIssues: data.body.unaffectedIssues });
        setTimelinessError(true);
      } else {
        dispatch(editNodDateUpdates(appealId, data.body.nodDateUpdate));
        dispatch(showSuccessMessage(successMessage));
        onSubmit?.();
        window.scrollTo(0, 0);
      }
    });
  };

  return (
    <EditNodDateModal
      onCancel={onCancel}
      onSubmit={handleSubmit}
      nodDate={nodDate}
      reason={reason}
      appealId={appealId}
      appellantName={appeal.appellantFullName}
      showTimelinessError={showTimelinessError}
      reasonErrorMessage={reasonErrorMessage}
      issues={issues}
      setBadDate={setBadDate}
      setBadReason={setBadReason}
      setReasonErrorMessage={setReasonErrorMessage}
    />
  );
};

export const EditNodDateModal = ({
  onCancel,
  onSubmit,
  nodDate,
  reason,
  reasonErrorMessage,
  showTimelinessError,
  issues,
  setBadDate,
  setBadReason,
  setReasonErrorMessage
}) => {
  const [receiptDate, setReceiptDate] = useState(nodDate);
  const [changeReason, setChangeReason] = useState(reason);
  const [dateErrorMessage, setDateErrorMessage] = useState(null);
  const [showWarning, setWarningMessage] = useState(false);

  const buttons = [];

  if (!showTimelinessError) {
    buttons.push({
      classNames: ['cf-modal-link', 'cf-btn-link'],
      name: 'Cancel',
      onClick: onCancel
    });
  }

  buttons.push({
    classNames: ['usa-button', 'usa-button-primary'],
    name: showTimelinessError ? 'Close' : 'Submit',
    onClick: showTimelinessError ? onCancel : () => onSubmit(receiptDate, changeReason)
  });

  const isFutureDate = (newDate) => {
    const today = new Date();
    const todaysDate = moment(today.toISOString());
    const date = moment(newDate);

    return (date > todaysDate);
  };

  const isPreAmaDate = (newDate) => {
    const formattedNewDate = moment(newDate);
    const amaDate = moment('2019-02-19');

    return (formattedNewDate < amaDate);
  };

  const isLaterThanNodDate = (newDate) => {
    const formattedNewDate = moment(newDate);
    const formattedNodDate = moment(nodDate);

    return (formattedNewDate > formattedNodDate);
  };

  const handleDateChange = (value) => {
    if (isFutureDate(value)) {
      setWarningMessage(false);
      setDateErrorMessage(COPY.EDIT_NOD_DATE_FUTURE_DATE_ERROR_MESSAGE);
      setReceiptDate(value);
      setBadDate(true);
    } else if (isPreAmaDate(value)) {
      setWarningMessage(false);
      setDateErrorMessage(COPY.EDIT_NOD_DATE_PRE_AMA_DATE_ERROR_MESSAGE);
      setReceiptDate(value);
      setBadDate(true);
    } else if (isLaterThanNodDate(value)) {
      setWarningMessage(true);
      setDateErrorMessage(null);
      setReceiptDate(value);
      setBadDate(false);
    } else {
      setWarningMessage(false);
      setDateErrorMessage(null);
      setReceiptDate(value);
      setBadDate(null);
    }
  };

  const handleChangeReason = (value) => {
    if (!value === null) {
      setBadReason(true);
      setReasonErrorMessage('Required');
    } else {
      setChangeReason(value);
      setBadReason(null);
      setReasonErrorMessage(null);
    }
  };

  let modalContent;

  if (showTimelinessError) {
    modalContent = <div>
      { showTimelinessError ? <Alert
        message={COPY.EDIT_NOD_DATE_TIMELINESS_ERROR_MESSAGE}
        styling={alertStyling}
        title={COPY.EDIT_NOD_DATE_TIMELINESS_ALERT_TITLE}
        type="error"
        scrollOnAlert={false}
      /> : null }

      <strong>Affected Issue(s)</strong>
      <ul className="cf-error">
        {issues.affectedIssues.map((issue) => {

          return <li key={issue.id}>
            {issue.description}
            <div>
              (Decision Date: <DateString date={issue.approx_decision_date} dateFormat = "MM/DD/YYYY" />)
            </div>
          </li>;
        })}
      </ul>

      { issues.unaffectedIssues.length > 0 && <strong>Unaffected Issue(s)</strong> }
      <ul>
        {issues.unaffectedIssues.map((issue) => {

          return <li key={issue.id}>
            {issue.description}
            <div>
              (Decision Date: <DateString date={issue.approx_decision_date} dateFormat = "MM/DD/YYYY" />)
            </div>
          </li>;
        })}
      </ul>
      <br />
      <div>
        <ReactMarkdown source={COPY.EDIT_NOD_DATE_TIMELINESS_COB_MESSAGE} />
      </div>
    </div>;
  } else {
    modalContent = <div>
      <div>
        <ReactMarkdown source={COPY.EDIT_NOD_DATE_MODAL_DESCRIPTION} />
      </div>
      { showWarning ? <Alert
        message={COPY.EDIT_NOD_DATE_WARNING_ALERT_MESSAGE}
        styling={alertStyling}
        title=""
        type="info"
        scrollOnAlert={false}
      /> : null }
      <DateSelector
        style={marginTop}
        name="nodDate"
        errorMessage={dateErrorMessage}
        label={COPY.EDIT_NOD_DATE_LABEL}
        strongLabel
        type="date"
        value={receiptDate}
        onChange={handleDateChange}
      />
      <SearchableDropdown
        name="reason"
        label="Reason for edit"
        errorMessage={reasonErrorMessage}
        searchable={false}
        placeholder="Select the reason..."
        value={changeReason}
        options={changeReasons}
        onChange={handleChangeReason}
        debounce={250}
        strongLabel
      />
    </div>;
  }

  return (
    <Modal
      title={COPY.EDIT_NOD_DATE_MODAL_TITLE}
      onCancel={onCancel}
      onSubmit={onSubmit}
      closeHandler={onCancel}
      buttons={buttons}>
      {modalContent}
    </Modal>
  );
};

EditNodDateModalContainer.propTypes = {
  onCancel: PropTypes.func.isRequired,
  onSubmit: PropTypes.func.isRequired,
  onClose: PropTypes.func,
  nodDate: PropTypes.string.isRequired,
  reason: PropTypes.object,
  appealId: PropTypes.string.isRequired
};

EditNodDateModal.propTypes = {
  onCancel: PropTypes.func.isRequired,
  onSubmit: PropTypes.func.isRequired,
  onClose: PropTypes.func,
  nodDate: PropTypes.string.isRequired,
  reason: PropTypes.object,
  appealId: PropTypes.string.isRequired,
  showTimelinessError: PropTypes.bool.isRequired,
  issues: PropTypes.object,
  reasonErrorMessage: PropTypes.string,
  setBadDate: PropTypes.func,
  setBadReason: PropTypes.func,
  setReasonErrorMessage: PropTypes.func
};
