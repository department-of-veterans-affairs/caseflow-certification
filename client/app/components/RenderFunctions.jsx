import React, { PropTypes } from 'react';

/* eslint-disable max-len */

/**
 * @param {string} text The text to associate with the spinning loading symbol.
 * defaults to 'Loading'.
 * @param {string} size The width and height of the loading symbol.
 * @param {string} color The color of the non-gray part of the caseflow logo.
 * @returns {string} The HTML for the loading symbol.
 */

export const loadingSymbolHtml = function(text = 'Loading', size = '30px', color = '#844E9F') {

  let imgSize = size;

  // if the callee only passed a number, append 'px'
  if (!(/\D/).test(imgSize)) {
    imgSize += 'px';
    console.warn(
      'loadingSymbolHtml() size argument', size, 'converted to', imgSize
    );
  }

  const style = { marginLeft: `-${imgSize}` };

  return (
      <div>
        <div className="cf-loading-button-text">
          {text}
        </div>
        <div className="cf-loading-button-symbol">
          <svg
            width={imgSize}
            height={imgSize}
            viewBox="0 0 500 500"
            className="cf-react-icon-loading-back">
            <path
              opacity="1"
              fill={color}
              fillOpacity="1"
              d="M249.9,362c-6.5,0-12.8,1.2-18.9,3.5l-34.4,13.3l12.7,28.8l33-12.8c2.4-0.9,5-1.4,7.5-1.4s5.1,0.5,7.5,1.4
                l33.2,12.8l12.7-28.8l-34.6-13.4C262.7,363.2,256.4,362,249.9,362 M418.9,319.9l-28.8,12.7l19.1,49.6c3.5,9,0.1,15.9-2.1,19.3
                c-4,5.8-10.4,9.3-17.2,9.3h0c-2.6,0-5.2-0.5-7.7-1.5l-49.5-19.1L320,418.9l50.9,19.7c6.2,2.4,12.6,3.6,19,3.6h0
                c17.1,0,33.2-8.6,43.1-23c9.8-14.3,11.9-32,5.5-48.3L418.9,319.9 M81,319.9l-19.7,51c-6.3,16.4-4.3,34,5.5,48.3
                c9.9,14.4,26,23,43.1,23c6.4,0,12.9-1.2,19-3.6l51-19.7l-12.7-28.8l-49.5,19.1c-2.5,1-5.1,1.4-7.6,1.4c-6.8,0-13.3-3.4-17.3-9.3
                c-2.3-3.3-5.6-10.3-2.1-19.2l19.1-49.6L81,319.9 M121.1,196.6l-28.8,12.7l12.8,33.1c1.9,4.9,1.9,10.2,0,15.1l-12.8,33.1l28.8,12.7
                l13.3-34.5c4.7-12.2,4.7-25.6,0-37.7L121.1,196.6 M378.8,196.5l-13.3,34.5c-4.7,12.2-4.7,25.6,0,37.7l13.3,34.5l28.8-12.7
                l-12.8-33.1c-1.9-4.9-1.9-10.2,0-15.1l12.8-33.1L378.8,196.5 M290.6,92.3l-33.2,12.8c-2.4,0.9-5,1.4-7.5,1.4
                c-2.6,0-5.1-0.5-7.5-1.4l-33-12.7l-12.7,28.8l34.4,13.3c6,2.3,12.4,3.5,18.8,3.5c6.4,0,12.8-1.2,18.9-3.5l34.6-13.4L290.6,92.3
                 M110,57.8c-17.1,0-33.2,8.6-43.1,23c-9.8,14.3-11.9,32-5.5,48.3L81,180l28.8-12.7l-19.1-49.4c-3.5-9-0.1-15.9,2.1-19.2
                c4-5.9,10.5-9.3,17.3-9.3c2.5,0,5.1,0.5,7.6,1.4l49.5,19.1L180,81.1l-50.9-19.7C122.9,59,116.5,57.8,110,57.8 M389.9,57.8
                c-6.4,0-12.9,1.2-19,3.6L319.9,81l12.7,28.8l49.5-19.1c2.5-1,5.1-1.4,7.6-1.4c6.8,0,13.3,3.4,17.3,9.3c2.3,3.3,5.6,10.3,2.1,19.2
                l-19.1,49.5l28.8,12.7l19.7-50.9c6.3-16.4,4.3-34-5.5-48.3C423.1,66.3,407,57.8,389.9,57.8M303.4,378.9l-12.7,28.8l29.3,11.3l12.7-28.8L303.4,378.9 M196.6,378.8l-29.3,11.3l12.7,28.8l29.3-11.3
                L196.6,378.8 M407.6,290.6l-28.8,12.7l11.3,29.3l28.8-12.7L407.6,290.6 M92.4,290.5L81,319.9l28.8,12.7l11.3-29.3L92.4,290.5
                 M109.8,167.2L81,180l11.3,29.3l28.8-12.7L109.8,167.2 M390.1,167.2l-11.3,29.3l28.8,12.7l11.3-29.3L390.1,167.2 M180,81.1
                l-12.7,28.8l29.3,11.3l12.7-28.8L180,81.1 M319.9,81l-29.3,11.3l12.7,28.8l29.3-11.3L319.9,81"/>
          </svg>
          <svg
            width={imgSize}
            height={imgSize}
            viewBox="0 0 500 500"
            style={style}
            className="cf-react-icon-loading-front">
            <path opacity="1"
              fill="#323a45"
              fillOpacity=".25"
              d="M209.3,407.5L180,418.9l22.1,50C210.6,488.1,229,500,250,500s39.4-11.9,47.9-31.1l22.1-49.9l-29.3-11.3
                l-21.5,48.5c-3.5,7.8-10.6,12.5-19.1,12.5c-8.5,0-15.7-4.7-19.1-12.5L209.3,407.5 M378.8,303.3l-33.8,15
                c-11.9,5.3-21.4,14.7-26.7,26.7l-15,33.9l29.3,11.3l14.4-32.5c2.1-4.8,5.9-8.6,10.7-10.7l32.4-14.3L378.8,303.3 M121.1,303.3
                l-11.3,29.3l32.4,14.4c4.8,2.1,8.6,5.9,10.7,10.7l14.4,32.5l29.3-11.3l-15-33.9c-5.3-11.9-14.8-21.4-26.7-26.7L121.1,303.3 M81,180
                l-49.9,22.1C11.9,210.6,0,228.9,0,249.9c0,21,11.9,39.4,31.1,47.9L81,319.9l11.3-29.3l-48.5-21.5c-7.8-3.5-12.5-10.6-12.5-19.1
                c0-8.5,4.7-15.7,12.5-19.1l48.5-21.5L81,180 M418.9,179.9l-11.3,29.3l48.6,21.5c7.8,3.5,12.5,10.6,12.5,19.1
                c0,8.5-4.7,15.7-12.5,19.1l-48.6,21.5l11.3,29.3l50-22.1c19.2-8.5,31.1-26.9,31.1-47.9s-11.9-39.4-31.1-47.9L418.9,179.9
                 M167.3,109.8L153,142.2c-2.1,4.8-5.9,8.6-10.7,10.7l-32.5,14.4l11.3,29.3l33.9-15c11.9-5.3,21.4-14.7,26.7-26.7l14.9-33.7
                L167.3,109.8 M332.7,109.8l-29.3,11.3l15,33.8c5.3,11.9,14.7,21.4,26.7,26.7l33.8,15l11.3-29.3l-32.4-14.4
                c-4.8-2.1-8.6-5.9-10.7-10.7L332.7,109.8 M250,0c-21,0-39.4,11.9-47.9,31.2L180,81.1l29.3,11.3l21.5-48.5
                c3.5-7.8,10.6-12.5,19.1-12.5c8.5,0,15.7,4.7,19.1,12.5l21.5,48.5L319.9,81l-22.1-49.9C289.3,11.9,271,0,250,0M303.4,378.9l-12.7,28.8l29.3,11.3l12.7-28.8L303.4,378.9 M196.6,378.8l-29.3,11.3l12.7,28.8l29.3-11.3
                L196.6,378.8 M407.6,290.6l-28.8,12.7l11.3,29.3l28.8-12.7L407.6,290.6 M92.4,290.5L81,319.9l28.8,12.7l11.3-29.3L92.4,290.5
                 M109.8,167.2L81,180l11.3,29.3l28.8-12.7L109.8,167.2 M390.1,167.2l-11.3,29.3l28.8,12.7l11.3-29.3L390.1,167.2 M180,81.1
                l-12.7,28.8l29.3,11.3l12.7-28.8L180,81.1 M319.9,81l-29.3,11.3l12.7,28.8l29.3-11.3L319.9,81"/>
          </svg>
        </div>
      </div>
  );
};

export let closeSymbolHtml = function() {
  return (
    <svg width="55" height="55" className="cf-icon-close"
      xmlns="http://www.w3.org/2000/svg" viewBox="0 0 55 55">
      <title>close</title>
      <path d="M52.6 46.9l-6 6c-.8.8-1.9 1.2-3 1.2s-2.2-.4-3-1.2l-13-13-13 13c-.8.8-1.9 1.2-3
        1.2s-2.2-.4-3-1.2l-6-6c-.8-.8-1.2-1.9-1.2-3s.4-2.2 1.2-3l13-13-13-13c-.8-.8-1.2-1.9-1.2-3s.4-2.2
        1.2-3l6-6c.8-.8 1.9-1.2 3-1.2s2.2.4 3 1.2l13 13 13-13c.8-.8 1.9-1.2 3-1.2s2.2.4 3 1.2l6 6c.8.8
        1.2 1.9 1.2 3s-.4 2.2-1.2 3l-13 13 13 13c.8.8 1.2 1.9 1.2 3s-.4 2.2-1.2 3z"/>
    </svg>
  );
};

export const successSymbolHtml = function() {
  return (
    <svg width="55" height="55" class="cf-icon-found"
    xmlns="http://www.w3.org/2000/svg" viewBox="0 0 60 50">
      <title>success</title>
      <path d="M57 13.3L29.9 41.7 24.8 47c-.7.7-1.6 1.1-2.5 1.1-.9 0-1.9-.4-2.5-1.1l-5.1-5.3L1
       27.5c-.7-.7-1-1.7-1-2.7s.4-2 1-2.7l5.1-5.3c.7-.7 1.6-1.1 2.5-1.1.9 0 1.9.4 2.5 1.1l11
       11.6L46.8 2.7c.7-.7 1.6-1.1 2.5-1.1.9 0 1.9.4 2.5 1.1L57 8c.7.7 1 1.7 1 2.7 0 1-.4 1.9-1
       2.6z"/>
    </svg>
  );
};

export const missingSymbolHtml = function() {
  return (
    <svg width="55" height="55" class="cf-icon-missing"
    xmlns="http://www.w3.org/2000/svg" viewBox="0 0 55 55">
      <title>missing icon</title>
      <path d="M52.6 46.9l-6 6c-.8.8-1.9 1.2-3 1.2s-2.2-.4-3-1.2l-13-13-13
      13c-.8.8-1.9 1.2-3 1.2s-2.2-.4-3-1.2l-6-6c-.8-.8-1.2-1.9-1.2-3s.4-2.2
      1.2-3l13-13-13-13c-.8-.8-1.2-1.9-1.2-3s.4-2.2 1.2-3l6-6c.8-.8 1.9-1.2
      3-1.2s2.2.4 3 1.2l13 13 13-13c.8-.8 1.9-1.2 3-1.2s2.2.4 3 1.2l6 6c.8.8
      1.2 1.9 1.2 3s-.4 2.2-1.2 3l-13 13 13 13c.8.8 1.2 1.9 1.2 3s-.4 2.2-1.2 3z"/>
    </svg>
  );
};

export const checkSymbolHtml = function() {
  return (
    <i className="fa fa-check fa-1 cf-tab-check" aria-hidden="true"></i>
  );
};

export const crossSymbolHtml = function() {
  return (
    <i className="fa fa-times fa-1 cf-tab-cross" aria-hidden="true"></i>
  );
};

export const GithubIcon = function() {
  return (
    <i className="fa fa-github fa-1" aria-hidden="true"></i>
  );
};

export const plusIcon = function() {
  return <svg width="12px" height="12px" viewBox="0 0 15 15">
      <g stroke="none" strokeWidth="1" fill="none" fillRule="evenodd">
          <g fillRule="nonzero" fill="#FFFFFF">
              <g>
                  <path d="M14.7014925,5.75279851 C14.5026119,5.55391791 14.2609701,5.45451493 13.9769776,5.45451493 L9.54514925,5.45451493 L9.54514925,1.02276119 C9.54514925,0.73880597 9.44570896,0.497238806 9.24690299,0.298358209 C9.04802239,0.0994776119 8.80671642,0 8.52227612,0 L6.47712687,0 C6.1930597,0 5.95156716,0.0993656716 5.75268657,0.298246269 C5.55380597,0.497126866 5.45440299,0.738656716 5.45440299,1.02264925 L5.45440299,5.45455224 L1.02268657,5.45455224 C0.738656716,5.45455224 0.497126866,5.55395522 0.298246269,5.75283582 C0.0993656716,5.95171642 0,6.19302239 0,6.47723881 L0,8.52268657 C0,8.8069403 0.0993283582,9.04828358 0.298208955,9.2469403 C0.497089552,9.44593284 0.738619403,9.54526119 1.02261194,9.54526119 L5.45432836,9.54526119 L5.45432836,13.9772388 C5.45432836,14.261194 5.55376866,14.5029851 5.75264925,14.7017537 C5.95152985,14.9004478 6.19317164,14.9997761 6.47720149,14.9997761 L8.52238806,14.9997761 C8.80664179,14.9997761 9.04802239,14.9004478 9.2469403,14.7017537 C9.44589552,14.5028731 9.54522388,14.2612313 9.54522388,13.9772388 L9.54522388,9.54526119 L13.9769403,9.54526119 C14.261194,9.54526119 14.5026866,9.44593284 14.7014552,9.24697761 C14.9001493,9.04809701 14.9995896,8.80679104 14.9995896,8.52253731 L14.9995896,6.47701493 C14.9995896,6.19287313 14.9003358,5.95141791 14.7013433,5.75264925 L14.7014925,5.75279851 Z" id="Shape"></path>
              </g>
          </g>
      </g>
    </svg>;
};

export class CategoryIcon extends React.PureComponent {
  render() {
    return <svg width="20px" height="20px" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg">
        <g stroke="none" strokeWidth="1" fill="none" fillRule="evenodd">
            <g fill={this.props.color}>
                <path d="M4.64092309,1 C3.21738445,1 2,2.16989858 2,3.68789356 L2,17.9336416 C2,18.2762127 2.06871806,18.7149247 2.37159862,19.0431298 C2.67415351,19.371335 3.04184399,19.4258517 3.32062438,19.4258517 C3.47694983,19.4229048 3.62839011,19.3683882 3.75800997,19.2674586 L10.4497163,14.2184033 L17.1414226,19.2674586 C17.2700654,19.3683882 17.4215057,19.4229048 17.5791339,19.4258517 C17.8575886,19.4258517 18.2252791,19.371335 18.5268569,19.0431298 C18.8297375,18.7149247 18.8984556,18.2762127 18.8984556,17.9336416 L18.8984556,3.68789356 C18.8984556,2.16989858 17.6820481,1 16.2585095,1 L4.64092309,1 Z"></path>
            </g>
        </g>
    </svg>;
  }
}

export const SelectedFilterIcon = ({ idPrefix, getRef, ...restProps }) => {
  const pathId = `${idPrefix}-path-1`;
  const filterId = `${idPrefix}-filter-2`;

  return <svg width="21px" height="21px" viewBox="0 0 21 21" {...restProps} ref={getRef}>
      <defs>
          <path d="M16.8333333,20 L4.16666667,20 C2.37222222,20 1,18.6277778 1,16.8333333 L1,4.16666667 C1,2.37222222 2.37222222,1 4.16666667,1 L15,1 L16.8333333,1 C18.6277778,1 20,2.37222222 20,4.16666667 L20,16.8333333 C20,18.6277778 18.6277778,20 16.8333333,20 Z" id={pathId}></path>
          <filter x="-10.5%" y="-10.5%" width="121.1%" height="121.1%" filterUnits="objectBoundingBox" id={filterId}>
              <feGaussianBlur stdDeviation="1.5" in="SourceAlpha" result="shadowBlurInner1"></feGaussianBlur>
              <feOffset dx="0" dy="1" in="shadowBlurInner1" result="shadowOffsetInner1"></feOffset>
              <feComposite in="shadowOffsetInner1" in2="SourceAlpha" operator="arithmetic" k2="-1" k3="1" result="shadowInnerInner1"></feComposite>
              <feColorMatrix values="0 0 0 0 0   0 0 0 0 0.443137255   0 0 0 0 0.737254902  0 0 0 1 0" type="matrix" in="shadowInnerInner1"></feColorMatrix>
          </filter>
      </defs>
      <g stroke="none" strokeWidth="1" fill="none" fillRule="evenodd">
          <g>
              <g transform="translate(5.000000, 6.000000)" fillRule="nonzero" fill="#323A45">
                  <path d="M10.9765625,0.3046875 C11.0651042,0.518229167 11.0286458,0.700520833 10.8671875,0.8515625 L7.015625,4.703125 L7.015625,10.5 C7.015625,10.71875 6.9140625,10.8723958 6.7109375,10.9609375 C6.64322917,10.9869792 6.578125,11 6.515625,11 C6.375,11 6.2578125,10.9505208 6.1640625,10.8515625 L4.1640625,8.8515625 C4.06510417,8.75260417 4.015625,8.63541667 4.015625,8.5 L4.015625,4.703125 L0.1640625,0.8515625 C0.00260416666,0.700520833 -0.0338541667,0.518229167 0.0546875,0.3046875 C0.143229167,0.1015625 0.296875,0 0.515625,0 L10.515625,0 C10.734375,0 10.8880208,0.1015625 10.9765625,0.3046875 Z"></path>
              </g>
              <g fillOpacity="1" fill="black">
                  <use filter={`url(#${filterId})`} xlinkHref={`#${pathId}`}></use>
              </g>
          </g>
      </g>
  </svg>;
};

SelectedFilterIcon.propTypes = {
  idPrefix: PropTypes.string.isRequired,
  getRef: PropTypes.func,
  className: PropTypes.string
};

export const UnselectedFilterIcon = (props) => {
  const { getRef, className, ...restProps } = props;

  return <svg width="21px" height="21px" viewBox="0 0 21 21" {...restProps} ref={getRef} className={`${className} unselected-filter-icon`}>
    <g stroke="none" strokeWidth="1" fill="none" fillRule="evenodd">
      <g transform="translate(5.000000, 6.000000)" fillRule="nonzero" className="unselected-filter-icon-inner">
        <path d="M10.9765625,0.3046875 C11.0651042,0.518229167 11.0286458,0.700520833 10.8671875,0.8515625 L7.015625,4.703125 L7.015625,10.5 C7.015625,10.71875 6.9140625,10.8723958 6.7109375,10.9609375 C6.64322917,10.9869792 6.578125,11 6.515625,11 C6.375,11 6.2578125,10.9505208 6.1640625,10.8515625 L4.1640625,8.8515625 C4.06510417,8.75260417 4.015625,8.63541667 4.015625,8.5 L4.015625,4.703125 L0.1640625,0.8515625 C0.00260416666,0.700520833 -0.0338541667,0.518229167 0.0546875,0.3046875 C0.143229167,0.1015625 0.296875,0 0.515625,0 L10.515625,0 C10.734375,0 10.8880208,0.1015625 10.9765625,0.3046875 Z"></path>
      </g>
      <path d="M16.8333333,20 L4.16666667,20 C2.37222222,20 1,18.6277778 1,16.8333333 L1,4.16666667 C1,2.37222222 2.37222222,1 4.16666667,1 L15,1 L16.8333333,1 C18.6277778,1 20,2.37222222 20,4.16666667 L20,16.8333333 C20,18.6277778 18.6277778,20 16.8333333,20 Z" className="unselected-filter-icon-border"></path>
    </g>
  </svg>;
};

export const rightTriangle = function() {
  return <svg width="11px" height="18px" viewBox="0 0 21 35">
      <g stroke="none" strokeWidth="1" fill="none" fillRule="evenodd">
        <g fillRule="nonzero" fill="#000000">
          <g transform="translate(3.000000, 4.000000)">
            <path d="M16,14.2222222 C16,14.7037037 15.8240741,15.1203704 15.4722222,15.4722222 L3.02777778,27.9166667 C2.67592593,28.2685185 2.25925926,28.4444444 1.77777778,28.4444444 C1.2962963,28.4444444 0.87962963,28.2685185 0.527777778,27.9166667 C0.175925926,27.5648148 0,27.1481481 0,26.6666667 L0,1.77777778 C0,1.2962963 0.175925926,0.87962963 0.527777778,0.527777778 C0.87962963,0.175925926 1.2962963,0 1.77777778,0 C2.25925926,0 2.67592593,0.175925926 3.02777778,0.527777778 L15.4722222,12.9722222 C15.8240741,13.3240741 16,13.7407407 16,14.2222222 Z" id="Shape"></path>
          </g>
        </g>
      </g>
    </svg>;
};

export const commentIcon = (selected, id) => {
  const filter = selected ? `url(#${id}-filter-1)` : '';

  return <svg width="40px" height="40px" viewBox="0 0 46 48" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <filter x="-13.8%" y="-8.8%" width="127.5%" height="127.5%" filterUnits="objectBoundingBox" id={`${id}-filter-1`}>
        <feOffset dx="0" dy="2" in="SourceAlpha" result="shadowOffsetOuter1"></feOffset>
        <feGaussianBlur stdDeviation="1.5" in="shadowOffsetOuter1" result="shadowBlurOuter1"></feGaussianBlur>
        <feColorMatrix values="0 0 0 0 0.0313725509   0 0 0 0 0.447058827   0 0 0 0 0.725490212  0 0 0 1 0" type="matrix" in="shadowBlurOuter1" result="shadowMatrixOuter1"></feColorMatrix>
        <feMerge>
          <feMergeNode in="shadowMatrixOuter1"></feMergeNode>
          <feMergeNode in="SourceGraphic"></feMergeNode>
        </feMerge>
      </filter>
    </defs>
    <g stroke="none" strokeWidth="1" fill="none" fillRule="evenodd">
      <g>
        <g filter={filter} transform="translate(23.000000, 23.000000) scale(-1, 1) translate(-23.000000, -23.000000) translate(3.000000, 3.000000)">
          <path d="M35.6756757,2.10526316 L35.6756757,2.10807018 C36.8922523,2.10807018 37.8378378,3.02877193 37.8378378,4.21333333 L37.8378378,25.2659649 C37.8378378,26.4498246 36.8922523,27.3712281 35.6756757,27.3712281 L30.8108108,27.3712281 C30.1715315,27.3684211 29.6706306,27.9024561 29.7297297,28.5221053 L30.5405405,36.1045614 L21.8414414,27.6645614 C21.6381982,27.4722807 21.3657658,27.365614 21.0810811,27.3684211 L4.32432432,27.3684211 C3.10774775,27.3684211 2.16216216,26.4470175 2.16216216,25.2631579 L2.16216216,4.21052632 C2.16216216,3.02596491 3.10774775,2.10526316 4.32432432,2.10526316 L35.6756757,2.10526316 Z M31.8918919,6.84210526 C32.4886486,6.84210526 32.972973,7.31368421 32.972973,7.89473684 C32.972973,8.47578947 32.4886486,8.94736842 31.8918919,8.94736842 L8.10810811,8.94736842 C7.51135135,8.94736842 7.02702703,8.47578947 7.02702703,7.89473684 C7.02702703,7.31368421 7.51135135,6.84210526 8.10810811,6.84210526 L31.8918919,6.84210526 Z M31.8918919,13.6842105 C32.4886486,13.6842105 32.972973,14.1557895 32.972973,14.7368421 C32.972973,15.3178947 32.4886486,15.7894737 31.8918919,15.7894737 L8.10810811,15.7894737 C7.51135135,15.7894737 7.02702703,15.3178947 7.02702703,14.7368421 C7.02702703,14.1557895 7.51135135,13.6842105 8.10810811,13.6842105 L31.8918919,13.6842105 Z M31.8918919,20.5263158 C32.4886486,20.5263158 32.972973,20.9978947 32.972973,21.5789474 C32.972973,22.16 32.4886486,22.6315789 31.8918919,22.6315789 L8.10810811,22.6315789 C7.51135135,22.6315789 7.02702703,22.16 7.02702703,21.5789474 C7.02702703,20.9978947 7.51135135,20.5263158 8.10810811,20.5263158 L31.8918919,20.5263158 Z" id="Page-1-Copy-12" fill="#EEDF1B"></path>
          <path d="M35.6756757,0.0184989194 C38.0518919,0.0184989194 40,1.91534102 40,4.22902524 L40,25.2816568 C40,27.595341 38.0518919,29.4921831 35.6756757,29.4921831 L32.0100901,29.4921831 L32.9895495,38.8507796 C33.0796396,39.8184989 31.8861261,40.3770954 31.1654054,39.7055165 L20.6421622,29.4921831 L4.32432432,29.4921831 C1.94810811,29.4921831 0,27.595341 0,25.2816568 L0,4.22902524 C0,1.91534102 1.94810811,0.0184989194 4.32432432,0.0184989194 L35.6756757,0.0184989194 Z M35.6756757,2.12376208 L4.32432432,2.12376208 C3.10774775,2.12376208 2.16216216,3.04446383 2.16216216,4.22902524 L2.16216216,25.2816568 C2.16216216,26.4655165 3.10774775,27.38692 4.32432432,27.38692 L21.0810811,27.38692 C21.3657658,27.384113 21.6381982,27.4907796 21.8414414,27.6830603 L30.5405405,36.1230603 L29.7297297,28.5406042 C29.6706306,27.9209551 30.1715315,27.38692 30.8108108,27.389727 L35.6756757,27.389727 C36.8922523,27.389727 37.8378378,26.4683235 37.8378378,25.2844638 L37.8378378,4.23183225 C37.8378378,3.04727085 36.8922523,2.12656909 35.6756757,2.12656909 L35.6756757,2.12376208 Z M31.8918919,6.86060418 C32.4886486,6.86060418 32.972973,7.33218313 32.972973,7.91323576 C32.972973,8.49428839 32.4886486,8.96586734 31.8918919,8.96586734 L8.10810811,8.96586734 C7.51135135,8.96586734 7.02702703,8.49428839 7.02702703,7.91323576 C7.02702703,7.33218313 7.51135135,6.86060418 8.10810811,6.86060418 L31.8918919,6.86060418 Z M31.8918919,13.7027094 C32.4886486,13.7027094 32.972973,14.1742884 32.972973,14.755341 C32.972973,15.3363937 32.4886486,15.8079726 31.8918919,15.8079726 L8.10810811,15.8079726 C7.51135135,15.8079726 7.02702703,15.3363937 7.02702703,14.755341 C7.02702703,14.1742884 7.51135135,13.7027094 8.10810811,13.7027094 L31.8918919,13.7027094 Z M31.8918919,20.5448147 C32.4886486,20.5448147 32.972973,21.0163937 32.972973,21.5974463 C32.972973,22.1784989 32.4886486,22.6500779 31.8918919,22.6500779 L8.10810811,22.6500779 C7.51135135,22.6500779 7.02702703,22.1784989 7.02702703,21.5974463 C7.02702703,21.0163937 7.51135135,20.5448147 8.10810811,20.5448147 L31.8918919,20.5448147 Z" id="Page-1" fill="#5B616B"></path>
        </g>
      </g>
    </g>
  </svg>;
};

export const closeIcon = () => {
  return <svg width="12px" height="12px" viewBox="0 0 12 12" xmlns="http://www.w3.org/2000/svg">
    <g stroke="none" strokeWidth="1" fill="none" fillRule="evenodd">
      <g fillRule="nonzero" fill="#000000">
        <g>
          <path d="M11.7923265,9.64946939 C11.7923265,9.9115102 11.7004898,10.1348571 11.5168163,10.3185306 L10.178449,11.6566531 C9.99477551,11.8403265 9.77191837,11.9321633 9.50938776,11.9321633 C9.24734694,11.9321633 9.024,11.8403265 8.84032653,11.6566531 L5.94759184,8.76391837 L3.05461224,11.6566531 C2.87093878,11.8403265 2.64808163,11.9321633 2.38555102,11.9321633 C2.1235102,11.9321633 1.90065306,11.8403265 1.71697959,11.6566531 L0.378612245,10.3185306 C0.194938776,10.1348571 0.103102041,9.912 0.103102041,9.64946939 C0.103102041,9.38693878 0.194938776,9.16408163 0.378612245,8.98040816 L3.27134694,6.08742857 L0.378367347,3.19469388 C0.194693878,3.01102041 0.102857143,2.78816327 0.102857143,2.52563265 C0.102857143,2.26285714 0.194693878,2.04 0.378367347,1.85632653 L1.71673469,0.518204082 C1.90040816,0.334530612 2.12326531,0.24244898 2.38530612,0.24244898 C2.64808163,0.24244898 2.87093878,0.334530612 3.05461224,0.518204082 L5.94759184,3.41142857 L8.84032653,0.517959184 C9.024,0.334285714 9.24685714,0.24244898 9.50938776,0.24244898 C9.77191837,0.24244898 9.99477551,0.334530612 10.1786939,0.518204082 L11.5168163,1.85632653 C11.7004898,2.04 11.7923265,2.26285714 11.7923265,2.52538776 C11.7923265,2.78791837 11.7004898,3.01102041 11.5168163,3.19469388 L8.62383673,6.08742857 L11.5168163,8.98040816 C11.7004898,9.16408163 11.7923265,9.38693878 11.7923265,9.64946939 Z" id="Shape"></path>
        </g>
      </g>
    </g>
</svg>;
};

export const lockIcon = (isLocked) =>
  <svg width="18px" height="20px" viewBox="0 0 18 20" version="1.1"
      xmlns="http://www.w3.org/2000/svg" className="cf-lock-icon">
      <g stroke="none" strokeWidth="1" fill="none" fillRule="evenodd">
          <g fillRule="nonzero" fill={ isLocked ? '#323A45' : '#AEB0B5' }>
              <g id="padlock" transform="translate(2.000000, 1.000000)">
                  <path d="M13.6372727,8.06531592 C13.4111091,7.83991791 13.1366667,7.72730348
                    12.8135212,7.72730348 L12.4261455,7.72730348 L12.4261455,5.40900249
                    C12.4261455,3.92797264 11.8933394,2.65631343 10.8273879,1.59381343
                    C9.76152121,0.531271144 8.48590909,0 6.99991515,0 C5.51396364,0 4.23809697,0.531271144
                    3.17231515,1.59377114 C2.10636364,2.65631343 1.57355758,3.92793035 1.57355758,5.40900249
                    L1.57355758,7.72730348 L1.18601212,7.72730348 C0.863121212,7.72730348 0.588509091,7.83991791
                    0.362387879,8.06531592 C0.136266667,8.29054478 0.0232484848,8.56427861
                    0.0232484848,8.88643284 L0.0232484848,15.8408706 C0.0232484848,16.1627289 0.136309091,16.4365473
                    0.362387879,16.6619876 C0.588509091,16.8871741 0.863121212,16.9999154 1.18601212,16.9999154
                    L12.8138182,16.9999154 C13.1369636,16.9999154 13.4113636,16.887301 13.6375697,16.6619876
                    C13.8634788,16.4365473 13.9767091,16.1627289 13.9767091,15.8408706 L13.9767091,8.88630597
                    C13.9768788,8.56440547 13.8634788,8.29071393 13.6372727,8.06531592 Z M10.1006606,7.72730348
                    L3.8991697,7.72730348 L3.8991697,5.40900249 C3.8991697,4.55583085 4.20203636,3.82732587
                    4.80764242,3.22374129 C5.41333333,2.62007214 6.14404848,2.318301 7.00004242,2.318301
                    C7.85612121,2.318301 8.58666667,2.62002985 9.1924,3.22374129 C9.79783636,3.82728358
                    10.1006606,4.55583085 10.1006606,5.40900249 L10.1006606,7.72730348 Z" id="Shape">
                  </path>
              </g>
          </g>
      </g>
  </svg>;

/* eslint-enable max-len */
