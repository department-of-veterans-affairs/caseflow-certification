import React from 'react';
import PropTypes from 'prop-types';
// import { editAppeal, poaSyncDateUpdates } from '../QueueActions';
// import { useDispatch, useSelector } from 'react-redux';
// import ApiUtil from '../../util/ApiUtil';
import Button from '../../components/Button';
import Alert from '../../components/Alert';
import COPY from '../../../COPY';
import { css } from 'glamor';
import { sprintf } from 'sprintf-js';

import { boldText } from '../constants';
import { PoaRefreshButton } from './PoaRefreshButton';

export const textStyling = css({
  display: 'flex',
  justifyContent: 'space-between',
  fontSize: '.8em'
});

export const PoaRefresh = ({ powerOfAttorney }) => {
  const poaSyncInfo = {
    poaSyncDate: powerOfAttorney.poa_last_synced_at
  };

  const updatePOA = () => {
    fetch('/appeals/693be0ff-98ce-4d31-b4aa-43d65a1083d6/update_power_of_attorney')
      .then(res => res.json())
      .then(
        (result) => {
          alert = {
            type: result.status,
            message: result.message
          }
          console.log(alert)
        }
      )
  };

  const lastSyncedCopy = sprintf(COPY.CASE_DETAILS_POA_LAST_SYNC_DATE_COPY, poaSyncInfo);

  return (
    <div {...textStyling}>
      <i>Power of Attorney (POA) data comes from VBMS. To refresh POA, please click the "Refresh POA" button.</i>
      <i {...boldText}>{lastSyncedCopy}</i>
    </div>
  );
};

PoaRefresh.propTypes = {
  powerOfAttorney: PropTypes.shape({
    poa_last_synced_at: PropTypes.string
  })

};
