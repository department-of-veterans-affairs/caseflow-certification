import React from 'react';
import { useArgs } from '@storybook/client-api';

import FilterOption from './FilterOption';

/* eslint-disable react/prop-types */

export default {
  title: 'Commons/Components/FilterOption',
  component: FilterOption,
  parameters: {
    controls: { expanded: true },
  },
  args: {
    options: [
      {
        displayText: 'Attorney Legacy Tasks',
        value: 'AttorneyLegacyTask',
        checked: true,
      },
      {
        displayText: 'Establish Claim',
        value: 'EstablishClaim',
        checked: false,
      },
    ],
  },
  argTypes: { setSelectedValue: { action: 'clicked' } }
};

export const Controlled = (args) => {
  // eslint-disable-next-line no-unused-vars
  const [_args, updateArgs] = useArgs();

  const handleChange = (val) => {
    const newOptions = args.options.map((opt) => opt.value === val ? { ...opt, checked: !opt.checked } : opt);

    updateArgs({ options: newOptions });
    args.setSelectedValue(val);
  };

  return <FilterOption {...args} setSelectedValue={handleChange} />;
};
