import React from 'react';

import { IssueRemandReasonCheckbox } from './IssueRemandReasonCheckbox';

/* eslint-disable react/prop-types */

const option = {
  id: 'option1',
};

export default {
  title: 'Queue/Components/Remand Reasons/IssueRemandReasonCheckbox',
  component: IssueRemandReasonCheckbox,
  parameters: {
    controls: { expanded: true },
  },
  args: {
    option,
  },
  argTypes: {
    onChange: { action: 'onChange' },
  },
};

const Template = (args) => <IssueRemandReasonCheckbox {...args} />;

export const AMA = Template.bind({});
AMA.args = { isLegacyAppeal: false };

export const Legacy = Template.bind({});
Legacy.args = { isLegacyAppeal: true };
