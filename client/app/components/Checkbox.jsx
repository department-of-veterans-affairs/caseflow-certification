import React from 'react';
import PropTypes from 'prop-types';
import classnames from 'classnames';

export default class Checkbox extends React.Component {
  onChange = (event) => {
    this.props.onChange(event.target.checked);
  }

  render() {
    let {
      label,
      name,
      required,
      value,
      disabled,
      id,
      errorMessage,
      unpadded,
      hideLabel
    } = this.props;

    let classNames = [
      `checkbox-wrapper-${name}`
    ];

    if (!unpadded) {
      classNames.push('cf-form- qa`');
    }

    if (errorMessage) {
      classNames.push('usa-input-error');
    }

    return <div className={classNames.join(' ')}>
      {errorMessage && <div className="usa-input-error-message">{errorMessage}</div>}
      <div className="cf-form-check">
        <input
          name={name}
          onChange={this.onChange}
          type="checkbox"
          id={id || name}
          checked={value}
          disabled={disabled}
          aria-label="label"
        />
        <label className="question-label" htmlFor={name}>
          <div className={ classnames({ 'usa-sr-only': hideLabel }) }>{(label || name)}</div> {required && <span className="cf-required">Required</span>}
        </label>
      </div>
    </div>;
  }
}
Checkbox.defaultProps = {
  required: false
};

Checkbox.propTypes = {
  label: PropTypes.node,
  name: PropTypes.string.isRequired,
  onChange: PropTypes.func.isRequired,
  required: PropTypes.bool.isRequired,
  disabled: PropTypes.bool,
  hideLabel: PropTypes.bool,
  value: PropTypes.bool
};
