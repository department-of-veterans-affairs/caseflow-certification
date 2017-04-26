import React, { PropTypes } from 'react';

export default class AlertMessage extends React.Component {
  render() {
    let {
      leadMessageList,
      messageText,
      title
    } = this.props;

    return <div className="cf-app-msg-screen cf-app-segment
      cf-app-segment--alt">
      <h1 className="cf-red-text cf-msg-screen-heading">{title}</h1>
      {leadMessageList.map((listValue) =>
        <h2 className="cf-msg-screen-deck" key={listValue}>
          {listValue}
        </h2>)
      }
      <p className="cf-msg-screen-text">
        { messageText }
      </p>
    </div>;
  }
}

AlertMessage.props = {
  leadMessageList: PropTypes.array,
  messageText: PropTypes.string,
  title: PropTypes.string
};
