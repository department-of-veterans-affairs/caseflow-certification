import React from 'react';
import { FormProvider } from 'react-hook-form';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import { connect, useDispatch, useSelector } from 'react-redux';
import PropTypes from 'prop-types';

import { ClaimantForm as EditClaimantForm } from '../../intake/addClaimant/ClaimantForm';
import { useClaimantForm } from '../../intake/addClaimant/utils';
import Button from '../../components/Button';
import { updateAppellantInformation } from './editAppellantInformationSlice';
import { EDIT_CLAIMANT_PAGE_DESCRIPTION } from 'app/../COPY';
import { appealWithDetailSelector } from '../selectors';
import { mapAppellantDataFromApi } from './utils';

const EditAppellantInformation = ({ appealId }) => {
  const dispatch = useDispatch();
  const appeal = useSelector((state) =>
    appealWithDetailSelector(state, { appealId })
  );

  const methods = useClaimantForm({ defaultValues: mapAppellantDataFromApi(appeal) });
  const {
    handleSubmit,
  } = methods;

  const handleUpdate = (formData) => {
    const id = appeal.unrecognizedAppellantId;

    dispatch(updateAppellantInformation({ formData, id }));
  };

  const editAppellantHeader = 'Edit Appellant Information';
  const editAppellantDescription = EDIT_CLAIMANT_PAGE_DESCRIPTION;

  return <div>
    <FormProvider {...methods}>
      <AppSegment filledBackground>
        <EditClaimantForm
          editAppellantHeader={editAppellantHeader}
          editAppellantDescription={editAppellantDescription}
        />
        <Button onClick={handleSubmit(handleUpdate)}>Submit</Button>
      </AppSegment>
    </FormProvider>
  </div>;
};

EditAppellantInformation.propTypes = {
  appealId: PropTypes.string,
  testCallback: PropTypes.func
};

export default connect()(EditAppellantInformation);
