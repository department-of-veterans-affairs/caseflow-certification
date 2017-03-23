import React, { PropTypes } from 'react';
import ProgressBarSection from './ProgressBarSection';

export default class ProgressBar extends React.Component {
  render() {
    let {
      sections
    } = this.props;

    let currentSectionIndex;

    this.props.sections.forEach((section, i) => {
      if (section.current === true) {
        currentSectionIndex = i;
      }
    });

    return <div className="cf-app-segment">
      <div className="cf-progress-bar">
        {sections.map((section, i) => {
          if (i <= currentSectionIndex && i !== null) {
            section.activated = true;
          } else {
            section.activated = false;
          }

          return <ProgressBarSection
            activated={section.activated}
            key={i}
            title={section.title}
          />;
        })}
      </div>
    </div>;
  }
}

ProgressBar.propTypes = {
  sections: PropTypes.arrayOf(
    PropTypes.shape({
      activated: React.PropTypes.boolean,
      title: React.PropTypes.string
    })
  )
};
