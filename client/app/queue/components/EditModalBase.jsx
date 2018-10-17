import React from 'react';
import Modal from '../../components/Modal';
import { connect } from 'react-redux';
import Alert from '../../components/Alert';
import { css } from 'glamor';
import { withRouter } from 'react-router-dom';

const bottomMargin = css({
  marginBottom: '1.5rem'
});

export default function editModalBase(ComponentToWrap, { title, button, propsToText }) {
  class WrappedComponent extends React.Component {
    constructor(props) {
      super(props);

      this.state = { loading: false };
    }

    getWrappedComponentRef = (ref) => this.wrappedComponent = ref;

    closeHandler = () => {
      this.props.history.replace('/queue');
    }

    title = () => title || (propsToText && propsToText(this.props).title);

    button = () => button || (propsToText && propsToText(this.props).button) || 'Submit';

    submit = () => {
      this.setState({ loading: true });

      this.wrappedComponent.submit().then(() => {
        this.setState({ loading: false });
        if (!this.props.error) {
          this.closeHandler();
        }
      }, () => {
        this.setState({ loading: false });
      });
    }

    render = () => {
      const { error } = this.props;

      return <Modal
        title={this.title()}
        buttons={[{
          classNames: ['usa-button', 'cf-btn-link'],
          name: 'Cancel',
          onClick: this.closeHandler
        }, {
          classNames: ['usa-button-secondary', 'usa-button-hover', 'usa-button-warning'],
          name: this.button(),
          loading: this.state.loading,
          onClick: this.submit
        }]}
        closeHandler={this.closeHandler}>
        {error &&
          <div {...bottomMargin}>
            <Alert type="error" title={error.title} message={error.detail} />
          </div>
        }
        <ComponentToWrap ref={this.getWrappedComponentRef} {...this.props} />
      </Modal>;
    }
  }

  const mapStateToProps = (state) => {
    return {
      error: state.ui.messages.error
    };
  };

  return withRouter(connect(mapStateToProps)(WrappedComponent));
}
