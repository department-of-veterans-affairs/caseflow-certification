// @flow
import React from 'react';
import PropTypes from 'prop-types';

import QueueSelectorDropdown from './QueueSelectorDropdown';
import COPY from '../../../COPY.json';

type Props = {|
  userId: number
|};

export default class QueueJudgeViewSelectorDropdown extends React.Component<Props> {
  render = () => {
    const url = window.location.pathname.split('/');
    const location = url[url.length - 1];
    const reviewHref = (['review', 'queue'].includes(location)) ? '#' : `/queue/${this.props.userId}/review`;
    const assignHref = (location === 'assign') ? '#' : `/queue/${this.props.userId}/assign`;

    const items = [
      {
        key: '0',
        href: reviewHref,
        label: COPY.REVIEW_MODE_LINK_LABEL
      },
      {
        key: '1',
        href: assignHref,
        label: COPY.ASSIGN_MODE_LINK_LABEL
      }
    ];

    return (
      <QueueSelectorDropdown items={items} />
    );
  }
}

QueueJudgeViewSelectorDropdown.propTypes = {
  userId: PropTypes.number
};
