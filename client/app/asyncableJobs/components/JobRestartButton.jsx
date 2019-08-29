import React from 'react';
import Button from '../../components/Button';
import ApiUtil from '../../util/ApiUtil';

class JobRestartButton extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      restarted: false,
      restarting: false
    };
  }

  restartJob = () => {
    this.setState({ restarting: true });
    this.sendRestart();
  }

  sendRestart = () => {
    const page = this;
    const job = this.props.job;
    const url = `/asyncable_jobs/${job.klass}/jobs/${job.id}`;

    ApiUtil.patch(url, {}).
      then(
        (response) => {
          const responseObject = JSON.parse(response.text);

          Object.assign(job, responseObject);

          job.error = '';
          job.restarted = true;

          page.setState({
            restarted: true,
            restarting: false
          });
        },
        (error) => {
          throw error;
        }
      ).
      catch((error) => error);
  }

  getButtonClassNames = () => {
    let classNames = ['usa-button'];

    if (this.state.restarting || this.state.restarted) {
      classNames.push('usa-button-disabled');
    }

    return classNames;
  }

  getButtonText = () => {
    let txt = 'Restart';

    if (this.state.restarting) {
      txt = 'Restarting';
    } else if (this.state.restarted) {
      txt = 'Restarted';
    } else if (this.disableRestart()) {
      txt = 'Queued';
    }

    return txt;
  }

  disableRestart = () => {
    const job = this.props.job;

    if (!job.attempted_at) {
      return true;
    }

    const fiveMinutes = 300000;

    const lastAttempted = new Date(job.attempted_at).getTime();
    const submittedAt = new Date(job.last_submitted_at).getTime();
    const now = new Date().getTime();

    if ((now - lastAttempted) < fiveMinutes || (now - submittedAt) < fiveMinutes) {
      return true;
    }

    return false;
  }

  render = () => {
    const job = this.props.job;

    return <Button
      id={`job-${job.klass}-${job.id}`}
      title={`${job.klass} ${job.id}`}
      loading={this.state.restarting}
      loadingText="Restarting..."
      disabled={this.disableRestart()}
      onClick={() => {
        this.restartJob();
      }}
      classNames={this.getButtonClassNames()}
      >{this.getButtonText()}</Button>;
  }
}

export default JobRestartButton;
