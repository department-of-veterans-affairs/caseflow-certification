import React from 'react';

/* eslint-disable max-len */

/**
 * @param {string} text The text to associate with the spinning loading symbol.
 * defaults to 'Loading'.
 * @param {string} size The width and height of the loading symbol.
 * @param {string} color The color of the non-gray part of the caseflow logo.
 * @returns {string} The HTML for the loading symbol.
 */

export let loadingSymbolHtml = function(text = 'Loading', size = '30px', color = '#844E9F') {

  let imgSize = size;

  // if the callee only passed a number, append 'px'
  if (!(/\D/).test(imgSize)) {
    imgSize += 'px';
    console.warn(
      "loadingSymbolHtml() size argument", size, "converted to", imgSize
    );
  }

  let style = { 'marginLeft': `-${imgSize}` };

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

export let commentIcon = function(selected) {
  let outlineColor = selected ? '#3e94cf' : '#5C626C';

  return <svg version="1.1" id="Layer_1" width="100%" height="100%" viewBox="0 0 75 75">
      <g>
        <defs>
          <path style={{ overflow: 'visible' }} id="comment-svg-id-1" d="M16.6,38.2c-1,0-1.9,0.9-1.9,1.9s0.9,1.9,1.9,1.9h41.7c1,0,1.9-0.9,1.9-1.9s-0.9-1.9-1.9-1.9H16.6z
             M16.6,25.8c-1,0-1.9,0.9-1.9,1.9c0,1,0.9,1.9,1.9,1.9h41.7c1,0,1.9-0.9,1.9-1.9c0-1-0.9-1.9-1.9-1.9H16.6z M16.6,13.5
            c-1,0-1.9,0.9-1.9,1.9s0.9,1.9,1.9,1.9h41.7c1,0,1.9-0.9,1.9-1.9s-0.9-1.9-1.9-1.9H16.6z M10,5h55c2.1,0,3.8,1.7,3.8,3.8v38
            c0,2.1-1.7,3.8-3.8,3.8H35.6c-0.5,0-1,0.2-1.3,0.5L19,66.3l1.4-13.7c0.1-1.1-0.8-2.1-1.9-2.1H10c-2.1,0-3.8-1.7-3.8-3.8v-38
            C6.2,6.6,7.8,5,10,5L10,5z"/>
        </defs>
        <clipPath id="comment-svg-id-2">
          <use xlinkHref="#comment-svg-id-1" style={{ overflow: 'visible' }}/>
        </clipPath>
        <rect x="-0.1" y="-1.4"
          style={{
            fill: '#EEDF1A',
            clipPath: 'url(#comment-svg-id-2)'
          }} width="75.3" height="73.9"/>
      </g>
      <g>
        <defs>
          <path style={{ overflow: 'visible' }} id="comment-svg-id-3" d="M16.6,38.2c-1,0-1.9,0.9-1.9,1.9c0,1,0.9,1.9,1.9,1.9h41.7c1,0,1.9-0.9,1.9-1.9c0-1-0.9-1.9-1.9-1.9H16.6z
             M16.6,25.9c-1,0-1.9,0.9-1.9,1.9c0,1,0.9,1.9,1.9,1.9h41.7c1,0,1.9-0.9,1.9-1.9c0-1-0.9-1.9-1.9-1.9H16.6z M16.6,13.5
            c-1,0-1.9,0.9-1.9,1.9s0.9,1.9,1.9,1.9h41.7c1,0,1.9-0.9,1.9-1.9s-0.9-1.9-1.9-1.9H16.6z M10,5h55c2.1,0,3.8,1.7,3.8,3.8v38
            c0,2.1-1.7,3.8-3.8,3.8H35.6c-0.5,0-1,0.2-1.3,0.5L19,66.3l1.4-13.7c0.1-1.1-0.8-2.1-1.9-2.1H10c-2.1,0-3.8-1.7-3.8-3.8v-38
            C6.2,6.7,7.8,5,10,5L10,5z M10,1.2c-4.2,0-7.6,3.4-7.6,7.6v38c0,4.2,3.4,7.6,7.6,7.6h6.4l-1.7,16.9c-0.2,1.7,1.9,2.8,3.2,1.5
            l18.5-18.4H65c4.2,0,7.6-3.4,7.6-7.6v-38c0-4.2-3.4-7.6-7.6-7.6H10z"/>
        </defs>
        <clipPath id="comment-svg-id-4">
          <use xlinkHref="#comment-svg-id-3" style={{ overflow: 'visible' }}/>
        </clipPath>
        <rect x="-3.9" y="-5.1"
          style={{
            fill: outlineColor,
            clipPath: 'url(#comment-svg-id-4)'
          }} width="82.9" height="84.7"/>
      </g>
    </svg>;
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

export let removeSymbolHtml = function() {
  return (
    <svg width="12px" height="12px" viewBox="0 0 12 12" version="1.1" xmlns="http://www.w3.org/2000/svg">
      <g id="Iteration-6" stroke="none" stroke-width="1" fill="none" fill-rule="evenodd">
          <g id="Artboard-2" fill-rule="nonzero" fill="#000000">
              <g id="svg+xml">
                  <path d="M11.7923265,9.64946939 C11.7923265,9.9115102 11.7004898,10.1348571 11.5168163,10.3185306 L10.178449,11.6566531 C9.99477551,11.8403265 9.77191837,11.9321633 9.50938776,11.9321633 C9.24734694,11.9321633 9.024,11.8403265 8.84032653,11.6566531 L5.94759184,8.76391837 L3.05461224,11.6566531 C2.87093878,11.8403265 2.64808163,11.9321633 2.38555102,11.9321633 C2.1235102,11.9321633 1.90065306,11.8403265 1.71697959,11.6566531 L0.378612245,10.3185306 C0.194938776,10.1348571 0.103102041,9.912 0.103102041,9.64946939 C0.103102041,9.38693878 0.194938776,9.16408163 0.378612245,8.98040816 L3.27134694,6.08742857 L0.378367347,3.19469388 C0.194693878,3.01102041 0.102857143,2.78816327 0.102857143,2.52563265 C0.102857143,2.26285714 0.194693878,2.04 0.378367347,1.85632653 L1.71673469,0.518204082 C1.90040816,0.334530612 2.12326531,0.24244898 2.38530612,0.24244898 C2.64808163,0.24244898 2.87093878,0.334530612 3.05461224,0.518204082 L5.94759184,3.41142857 L8.84032653,0.517959184 C9.024,0.334285714 9.24685714,0.24244898 9.50938776,0.24244898 C9.77191837,0.24244898 9.99477551,0.334530612 10.1786939,0.518204082 L11.5168163,1.85632653 C11.7004898,2.04 11.7923265,2.26285714 11.7923265,2.52538776 C11.7923265,2.78791837 11.7004898,3.01102041 11.5168163,3.19469388 L8.62383673,6.08742857 L11.5168163,8.98040816 C11.7004898,9.16408163 11.7923265,9.38693878 11.7923265,9.64946939 Z" id="Shape"></path>
              </g>
          </g>
      </g>
  </svg>
  );
};

export let successSymbolHtml = function() {
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

export let missingSymbolHtml = function() {
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

export let checkSymbolHtml = function() {
  return (
    <i className="fa fa-check fa-1 cf-tab-check" aria-hidden="true"></i>
  );
};

export let crossSymbolHtml = function() {
  return (
    <i className="fa fa-times fa-1 cf-tab-cross" aria-hidden="true"></i>
  );
};

export let GithubIcon = function() {
  return (
    <i className="fa fa-github fa-1" aria-hidden="true"></i>
  );
};

export const docCategoryIcon = (color) => () =>
  <svg width="20px" height="20px" viewBox="0 0 20 20" version="1.1" xmlns="http://www.w3.org/2000/svg">
      <g stroke="none" strokeWidth="1" fill="none" fillRule="evenodd">
          <g fill={color}>
              <path d="M4.64092309,1 C3.21738445,1 2,2.16989858 2,3.68789356 L2,17.9336416 C2,18.2762127 2.06871806,18.7149247 2.37159862,19.0431298 C2.67415351,19.371335 3.04184399,19.4258517 3.32062438,19.4258517 C3.47694983,19.4229048 3.62839011,19.3683882 3.75800997,19.2674586 L10.4497163,14.2184033 L17.1414226,19.2674586 C17.2700654,19.3683882 17.4215057,19.4229048 17.5791339,19.4258517 C17.8575886,19.4258517 18.2252791,19.371335 18.5268569,19.0431298 C18.8297375,18.7149247 18.8984556,18.2762127 18.8984556,17.9336416 L18.8984556,3.68789356 C18.8984556,2.16989858 17.6820481,1 16.2585095,1 L4.64092309,1 Z"></path>
          </g>
      </g>
  </svg>;

/* eslint-enable max-len */
