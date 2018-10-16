import React from 'react';
import Modal from '../../components/Modal';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';

import { highlightInvalidFormItems } from '../uiReducer/uiActions';

import Alert from '../../components/Alert';
import { css } from 'glamor';
import { withRouter } from 'react-router-dom';

const bottomMargin = css({
  marginBottom: '1.5rem'
});

export default function editModalBase(ComponentToWrap, title) {
  class WrappedComponent extends React.Component {
    constructor(props) {
      super(props);

      this.state = { loading: false };
    }

    getWrappedComponentRef = (ref) => this.wrappedComponent = ref;

    closeHandler = () => {
      this.props.history.goBack();
    }

    submit = () => {
      const {
        validateForm: validation = null
      } = this.wrappedComponent;

      if (validation && !validation()) {
        return this.props.highlightInvalidFormItems(true);
      }
      this.props.highlightInvalidFormItems(false);

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
        title={title}
        buttons={[{
          classNames: ['usa-button', 'cf-btn-link'],
          name: 'Cancel',
          onClick: this.closeHandler
        }, {
          classNames: ['usa-button-secondary', 'usa-button-hover', 'usa-button-warning'],
          name: 'Submit',
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

  const mapDispatchToProps = (dispatch) => bindActionCreators({
    highlightInvalidFormItems
  }, dispatch);

  return withRouter(connect(mapStateToProps, mapDispatchToProps)(WrappedComponent));
}
