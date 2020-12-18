import React from 'react';
import { render, screen, waitFor, fireEvent } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

import { DocketSwitchDenialForm } from 'app/queue/docketSwitch/denial/DocketSwitchDenialForm';
import {
  DOCKET_SWITCH_GRANTED_REQUEST_LABEL,
  DOCKET_SWITCH_DENIAL_INSTRUCTIONS,
} from 'app/../COPY';
import { sprintf } from 'sprintf-js';

// const instructions = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit';

describe('DocketSwitchReviewRequestForm', () => {
  const onSubmit = jest.fn();
  const onCancel = jest.fn();
  const appellantName = 'Claimant 1';
  const defaults = { onSubmit, onCancel, appellantName };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders correctly', () => {
    const { container } = render(<DocketSwitchReviewRequestForm {...defaults} />);

    expect(container).toMatchSnapshot();

    expect(screen.getByText(sprintf(DOCKET_SWITCH_GRANTED_REQUEST_LABEL, appellantName))).toBeInTheDocument();
    expect(screen.getByText(DOCKET_SWITCH_GRANTED_REQUEST_INSTRUCTIONS)).toBeInTheDocument();
  });

  it('fires onCancel', async () => {
    render(<DocketSwitchReviewRequestForm {...defaults} />);
    expect(onCancel).not.toHaveBeenCalled();

    await userEvent.click(screen.getByRole('button', { name: /cancel/i }));
    expect(onCancel).toHaveBeenCalled();
  });

  describe('form validation & submission', () => {
    const receiptDate = '2020-10-01';
    const fillForm = async () => {
      //   Set receipt date
      await fireEvent.change(screen.getByLabelText(/receipt date/i), { target: { value: receiptDate } });
    };

    it('disables submit until all fields valid', async () => {
      render(<DocketSwitchReviewRequestForm {...defaults} />);

      const submit = screen.getByRole('button', { name: /confirm/i });

      expect(onSubmit).not.toHaveBeenCalled();

      await fillForm();

      await userEvent.click(submit);
      expect(onSubmit).not.toHaveBeenCalled();

      // We need to wrap this in waitFor due to async nature of form validation
      await waitFor(() => {
        expect(submit).toBeDisabled();
      });

      await waitFor(() => {
        expect(submit).toBeEnabled();
      });

      await userEvent.click(submit);
      await waitFor(() => {
        expect(onSubmit).toHaveBeenCalled();
      });
    });
  });
});
