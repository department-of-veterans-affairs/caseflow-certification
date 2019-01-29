// @flow
import React from 'react';
import PropTypes from 'prop-types';
import { sprintf } from 'sprintf-js';

import QueueSelectorDropdown from './QueueSelectorDropdown';
import COPY from '../../../COPY.json';

type Props = {|
  organizations: Array<Object>
|};

export default class QueueOrganizationSelectorDropdown extends React.Component<Props> {
  render = () => {
    const { organizations } = this.props;
    const url = window.location.pathname.split('/');
    const location = url[url.length - 1];
    const queueHref = (location === 'queue') ? '#' : '/queue';

    const items = organizations.map((org, index) => {
      return {
        key: (index + 1).toString(),
        href: (location === org.url) ? '#' : `/organizations/${org.url}`,
        label: sprintf(COPY.CASE_LIST_TABLE_QUEUE_DROPDOWN_TEAM_CASES_LABEL, org.name)
      };
    });

    items.unshift(
      {
        key: '0',
        href: queueHref,
        label: COPY.CASE_LIST_TABLE_QUEUE_DROPDOWN_OWN_CASES_LABEL
      }
    );

    return <QueueSelectorDropdown items={items} />;
  }
}

QueueOrganizationSelectorDropdown.propTypes = {
  organizations: PropTypes.arrayOf(PropTypes.shape({
    name: PropTypes.string.isRequired,
    url: PropTypes.string.isRequired
  }))
};
