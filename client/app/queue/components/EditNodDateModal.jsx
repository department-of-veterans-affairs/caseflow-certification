import React, { useEffect } from 'react';
import ReactMarkdown from 'react-markdown';
import PropTypes from 'prop-types';
import Modal from 'app/components/Modal';
import DateSelector from 'app/components/DateSelector';
import COPY from 'app/../COPY';
import { useDispatch, useSelector } from 'react-redux';
import { Controller, useForm } from 'react-hook-form';
import { yupResolver } from '@hookform/resolvers/yup';
import * as yup from 'yup';
import { resetSuccessMessages, showSuccessMessage } from '../uiReducer/uiActions';
import { editAppeal } from '../QueueActions';
import ApiUtil from '../../util/ApiUtil';
import { sprintf } from 'sprintf-js';
import { formatDateStr } from '../../util/DateUtil';
import { appealWithDetailSelector } from '../selectors';
import SearchableDropdown from 'app/components/SearchableDropdown';

const changeReasons = [
  { label: 'New Form/Information Received', value: 'new_info' },
  { label: 'Data Entry Error', value: 'entry_error' },
];

export const EditNodDateModalContainer = ({ onCancel, onSubmit, nodDate, appealId, reason }) => {
  const dispatch = useDispatch();
  const appeal = useSelector((state) =>
    appealWithDetailSelector(state, { appealId })
  );

  useEffect(() => {
    dispatch(resetSuccessMessages());
  }, []);

  const handleCancel = () => onCancel();

  const handleSubmit = ({ nodDate, reason }) => {
    const alertInfo = {
      appellantName: (appeal.appellantFullName),
      nodDateStr: formatDateStr(nodDate, 'YYYY-MM-DD', 'MM/DD/YYYY'),
      receiptDateStr: formatDateStr(nodDate, 'YYYY-MM-DD', 'MM/DD/YYYY')
    };

    const title = COPY.EDIT_NOD_DATE_SUCCESS_ALERT_TITLE;
    const detail = (sprintf(COPY.EDIT_NOD_DATE_SUCCESS_ALERT_MESSAGE, alertInfo));

    const successMessage = {
      title,
      detail,
    };
    const payload = {
      data: {
        receipt_date: nodDate,
        change_reason: reason
      }
    };

    ApiUtil.patch(`/appeals/${appealId}/nod_date_update`, payload).then(() => {
      dispatch(editAppeal(appealId, { nodDate, reason }));
      dispatch(showSuccessMessage(successMessage));
      onSubmit?.();
      window.scrollTo(0, 0);
    });
  };

  return (
    <EditNodDateModal
      onCancel={handleCancel}
      onSubmit={handleSubmit}
      nodDate={nodDate}
      reason={reason}
      appealId={appealId}
      appellantName={appeal.appellantFullName}
    />
  );
};

export const EditNodDateModal = ({ onCancel, onSubmit, nodDate, reason }) => {
  const schema = yup.object().shape({
    nodDate: yup.date().
      min('2019-02-19', COPY.EDIT_NOD_DATE_PRE_AMA_DATE_ERROR_MESSAGE).
      max(new Date(), COPY.EDIT_NOD_DATE_FUTURE_DATE_ERROR_MESSAGE).
      typeError('Invalid date.').
      required(),
    reason: yup.string().required().
      oneOf(changeReasons.map((changeReason) => changeReason.value))
  });

  const { register, handleSubmit, errors, watch, control, formState } = useForm({
    defaultValues: { nodDate, reason },
    resolver: yupResolver(schema),
    mode: 'onChange',
    reValidateMode: 'onChange'
  });

  const buttons = [
    {
      classNames: ['cf-modal-link', 'cf-btn-link'],
      name: 'Cancel',
      onClick: onCancel
    },
    {
      classNames: ['usa-button', 'usa-button-primary'],
      name: 'Submit',

      // For future disable use cases
      disabled: !formState.isValid,
      onClick: () => handleSubmit(onSubmit)
    }
  ];

  // eslint-disable-next-line no-console
  console.log(watch(), errors, formState.isValid, formState.errors);

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
      <form onSubmit={handleSubmit(onSubmit)}>
        <DateSelector
          inputRef={register}
          name="nodDate"
          errorMessage={errors.nodDate?.message}
          label={COPY.EDIT_NOD_DATE_LABEL}
          strongLabel
          type="date"
        />
        <Controller
          name="reason"
          control={control}
          defaultValue={null}
          render={({ onChange, ...rest }) => (
            <SearchableDropdown
              {...rest}
              label="Reason for edit"
              placeholder="Select the reason..."
              options={changeReasons}
              debounce={250}
              strongLabel
              onChange={(valObj) => onChange(valObj?.value)}
            />
          )}
        />
      </form>
    </Modal>
  );
};

EditNodDateModalContainer.propTypes = {
  onCancel: PropTypes.func.isRequired,
  onSubmit: PropTypes.func.isRequired,
  nodDate: PropTypes.string.isRequired,
  reason: PropTypes.object,
  appealId: PropTypes.string.isRequired
};

EditNodDateModal.propTypes = {
  onCancel: PropTypes.func.isRequired,
  onSubmit: PropTypes.func.isRequired,
  nodDate: PropTypes.string.isRequired,
  reason: PropTypes.object,
  appealId: PropTypes.string.isRequired
};
