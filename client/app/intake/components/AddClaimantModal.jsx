import React, { useState, useMemo, useCallback } from 'react';
import PropTypes from 'prop-types';
import { debounce } from 'lodash';
import Modal from '../../components/Modal';
import { ADD_CLAIMANT_MODAL_TITLE, ADD_CLAIMANT_MODAL_DESCRIPTION } from '../../../COPY';
import ReactMarkdown from 'react-markdown';
import SearchableDropdown from '../../components/SearchableDropdown';
import ApiUtil from '../../util/ApiUtil';

const relationshipOpts = [{ label: 'Attorney (previously or currently)', value: 'attorney' }];

const fetchAttorneys = async (search = '') => {
  const res = await ApiUtil.get('/intake/attorneys', { query: { query: search } });

  return res?.body;
};
const getClaimantOpts = async (search = '', asyncFn) => {
  // Enforce minimum search length (we'll simply return empty array rather than throw error)
  if (search.length < 3) {
    return { options: [] };
  }

  const res = await asyncFn(search);
  const options = res.map((item) => ({
    label: item.name,
    value: item.participant_id
  }));

  return { options };
};
// We'll show all items returned from the backend instead of using default substring matching
const filterOptions = (options) => options;

export const AddClaimantModal = ({ onCancel, onSubmit, onSearch = fetchAttorneys }) => {
  const [claimant, setClaimant] = useState(null);
  const [relationship, setRelationship] = useState(relationshipOpts[0]);
  const isInvalid = useMemo(() => !claimant, [claimant]);
  const handleChangeRelationship = (value) => setRelationship(value);
  const handleChangeClaimant = (value) => setClaimant(value);

  const asyncFn = useCallback(
    debounce((search, callback) => {
      getClaimantOpts(search, onSearch).then((res) => callback(null, res));
    }, 250),
    [onSearch]
  );

  const buttons = [
    {
      classNames: ['cf-modal-link', 'cf-btn-link'],
      name: 'Cancel',
      onClick: onCancel
    },
    {
      classNames: ['usa-button', 'usa-button-primary'],
      name: 'Add this claimant',
      onClick: () => onSubmit({ name: claimant.label, participantId: claimant.value }),
      disabled: isInvalid
    }
  ];

  return (
    <Modal title={ADD_CLAIMANT_MODAL_TITLE} buttons={buttons} closeHandler={onCancel} id="add_claimant_modal">
      <div>
        <ReactMarkdown source={ADD_CLAIMANT_MODAL_DESCRIPTION} />
      </div>
      <SearchableDropdown
        name="relationship"
        label="Claimant's relationship to the veteran"
        onChange={handleChangeRelationship}
        value={relationship}
        options={relationshipOpts}
        debounce={250}
      />
      <SearchableDropdown
        name="claimant"
        label="Claimant's name"
        onChange={handleChangeClaimant}
        value={claimant}
        filterOptions={filterOptions}
        async={asyncFn}
        options={[]}
        debounce={250}
      />
    </Modal>
  );
};

AddClaimantModal.propTypes = {
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func,
  onSearch: PropTypes.func
};
