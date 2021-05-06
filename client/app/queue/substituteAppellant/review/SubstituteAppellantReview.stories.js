import React from 'react';
import { MemoryRouter } from 'react-router';

import { SubstituteAppellantReview } from './SubstituteAppellantReview';
import { queueWrapper as Wrapper } from '../../../../test/data/stores/queueStore';

export default {
  title: 'Queue/Substitute Appellant/SubstituteAppellantReview',
  component: SubstituteAppellantReview,
  decorators: [
    (Story) => (
      <MemoryRouter>
        <Story />
      </MemoryRouter>
    ),
  ],
  parameters: {},
  args: {
    existingValues: { substitutionDate: '2021-02-15',
      participantId: 'CLAIMANT_WITH_PVA_AS_VSO',
    },
  },
  argTypes: {
    onBack: { action: 'back' },
    onCancel: { action: 'cancel' },
    onSubmit: { action: 'submit' },
  },
};

const storeArgs = {
  substituteAppellant: {
    relationships:  [
      { value: 'CLAIMANT_WITH_PVA_AS_VSO',
        fullName: 'Bob Vance',
        relationshipType: 'Spouse',
        displayText: 'Bob Vance, Spouse',
      },
      { value: '"1129318238"',
        fullName: 'Cathy Smith',
        relationshipType: 'Child',
        displayText: 'Cathy Smith, Child',
      },
    ],
  }
};
const Template = (args) => (
  <Wrapper {...storeArgs}>
    <SubstituteAppellantReview {...args} />
  </Wrapper>
);

export const Basic = Template.bind({});

Basic.parameters = {
  docs: {
    storyDescription:
      'Used by an Intake or Clerk of the Board user to confirm a substitute appellant\'s information for an appeal',
  },
};
