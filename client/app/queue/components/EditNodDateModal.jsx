import React, { useState } from 'react';
import ReactMarkdown from 'react-markdown';
import PropTypes from 'prop-types';
import Modal from 'app/components/Modal';
import DateSelector from 'app/components/DateSelector';
import COPY from 'app/../COPY';
import { useDispatch } from 'react-redux';
import { resetSuccessMessages, showSuccessMessage } from '../uiReducer/uiActions';

export const EditNodDateModalContainer = ({ onCancel, onSubmit, nodDate }) => {
  const dispatch = useDispatch();

  const handleSubmit = () => {
    const successMessage = {
      title: COPY.EDIT_NOD_DATE_SUCCESS_ALERT_TITLE,
      detail: COPY.EDIT_NOD_DATE_SUCCESS_ALERT_MESSAGE,
    };

    dispatch(showSuccessMessage(successMessage));
    setTimeout(() => dispatch(resetSuccessMessages()), 5000);
    onSubmit?.();
  };

  return (
    <EditNodDateModal
      onCancel={onCancel}
      onSubmit={handleSubmit}
      nodDate={nodDate}
    />
  );
};

export const EditNodDateModal = ({ onCancel, onSubmit, nodDate }) => {
  const [receiptDate, setReceiptDate] = useState(nodDate);
  const [futureDate, setFutureDate] = useState(false);

  const buttons = [
    {
      classNames: ['cf-modal-link', 'cf-btn-link'],
      name: 'Cancel',
      onClick: onCancel
    },
    {
      classNames: ['usa-button', 'usa-button-primary'],
      name: 'Submit',
      disabled: futureDate,
      onClick: () => onSubmit(receiptDate)
    }
  ];

  const isFutureDate = (newDate) => {
    const today = new Date().getTime();
    const date = new Date(newDate).getTime();

    return (today - date) < 0;
  };

  const handleDateChange = (value) => {
    if (isFutureDate(value)) {
      setFutureDate(true);
      setReceiptDate(value);
    } else {
      setReceiptDate(value);
      setFutureDate(false);
    }
  };

  return (
    <Modal
      title={COPY.EDIT_NOD_DATE_MODAL_TITLE}
      onCancel={onCancel}
      onSubmit={onSubmit}
      closeHandler={onCancel}
      buttons={buttons}>
      <div>
        <ReactMarkdown source={COPY.EDIT_NOD_DATE_MODAL_DESCRIPTION} />
      </div>
      <DateSelector
        name={COPY.EDIT_NOD_DATE_LABEL}
        errorMessage={futureDate ? COPY.EDIT_NOD_DATE_ERROR_ALERT_MESSAGE : null}
        strongLabel
        type="date"
        value={receiptDate}
        onChange={handleDateChange}
      />
    </Modal>
  );
};

EditNodDateModalContainer.propTypes = {
  onCancel: PropTypes.func.isRequired,
  onSubmit: PropTypes.func.isRequired,
  nodDate: PropTypes.string.isRequired
};

EditNodDateModal.propTypes = {
  onCancel: PropTypes.func.isRequired,
  onSubmit: PropTypes.func.isRequired,
  nodDate: PropTypes.string.isRequired
};
