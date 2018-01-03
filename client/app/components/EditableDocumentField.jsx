import React from 'react';
import PropTypes from 'prop-types';
import classNames from 'classnames';
import Button from './Button';

export default class EditableDocumentField extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      editing: false
    };
  }

  inputRef = (node) => this.input = node;

  startEditing = () => this.setState({ editing: true });
  stopEditing = () => this.setState({ editing: false });

  onSave = () => {
    this.props.onSave(this.input.value);
    this.stopEditing();
  }
  onCancel = () => {
    this.props.onCancel();
    this.stopEditing();
  }
  onChange = (event) => this.props.onChange(event.target.value);

  componentDidUpdate = () => {
    if (this.props.errorMessage && !this.state.editing) {
      this.setState({ editing: true });
    }
  }

  render() {
    const {
      errorMessage,
      className,
      label,
      name,
      type,
      value,
      placeholder,
      title,
      maxLength,
    } = this.props;
    const buttonClasses = ['cf-btn-link', 'editable-field-btn-link'];
    let actionLinks, textDisplay;

    if (this.state.editing) {
      actionLinks = <span>
        <Button onClick={this.onCancel} classNames={buttonClasses}>
          Cancel
        </Button>&nbsp;|&nbsp;
        <Button onClick={this.onSave} classNames={buttonClasses}>
          Save
        </Button>
      </span>;
      textDisplay = <input
        className={className}
        name={name}
        id={name}
        onChange={this.onChange}
        type={type}
        value={value}
        placeholder={placeholder}
        title={title}
        maxLength={maxLength}
        ref={this.inputRef}
      />;
    } else {
      actionLinks = <span>
        <Button onClick={this.startEditing} classNames={buttonClasses}>
          Edit
        </Button>
      </span>
      textDisplay = <span>{value}</span>
    }

    return <div className={classNames(className, { 'usa-input-error': errorMessage })}>
      <strong>{label}</strong>
      {actionLinks}<br/>
      {errorMessage && <span className="usa-input-error-message">{errorMessage}</span>}
      {textDisplay}
    </div>;
  }
};

EditableDocumentField.defaultProps = {
  required: true,
};

EditableDocumentField.propTypes = {
  name: PropTypes.string,
  required: PropTypes.bool,
  onSave: PropTypes.func.isRequired,
  onCancel: PropTypes.func.isRequired,
};
