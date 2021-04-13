import React, { useEffect } from 'react';
import { useHistory, useParams } from 'react-router';
import { useDispatch, useSelector } from 'react-redux';
import { format } from 'date-fns';

import { SubstituteAppellantBasicsForm } from './SubstituteAppellantBasicsForm';

import {
  updateData,
  stepForward,
  fetchRelationships,
} from './substituteAppellant.slice';

export const SubstituteAppellantBasicsView = () => {
  const { appealId } = useParams();
  const dispatch = useDispatch();
  const history = useHistory();

  const {
    formData: existingValues,
    relationships,
    loadingRelationships,
  } = useSelector((state) => state.substituteAppellant);

  const handleCancel = () => history.push(`/queue/appeals/${appealId}`);
  const handleSubmit = async (formData) => {
    // Here we'll dispatch action to update Redux store with our form data
    // Initially, we may also dispatch async thunk action to submit the basics
    // to the backend because of how stories are sliced

    dispatch(
      updateData({
        formData: {
          ...formData,
          substitutionDate: format(formData.substitutionDate, 'yyyy-MM-dd'),
        },
      })
    );

    // Advance progressbar
    dispatch(stepForward());
  };

  // Load veteran relationships for this appeal
  useEffect(() => {
    dispatch(fetchRelationships({ appealId }));
  }, []);

  return (
    <SubstituteAppellantBasicsForm
      existingValues={existingValues}
      onCancel={handleCancel}
      onSubmit={handleSubmit}
      relationships={relationships}
      loadingRelationships={loadingRelationships}
    />
  );
};
