# frozen_string_literal: true
# rubocop:disable Metrics/ModuleLength
module ApplicationHelper
  MISSING_ICON = <<-HTML.freeze
    <svg width="55" height="55" class="cf-icon-missing"
    xmlns="http://www.w3.org/2000/svg" viewBox="0 0 55 55">
      <title>missing icon</title>
      <path d="M52.6 46.9l-6 6c-.8.8-1.9 1.2-3 1.2s-2.2-.4-3-1.2l-13-13-13
      13c-.8.8-1.9 1.2-3 1.2s-2.2-.4-3-1.2l-6-6c-.8-.8-1.2-1.9-1.2-3s.4-2.2
      1.2-3l13-13-13-13c-.8-.8-1.2-1.9-1.2-3s.4-2.2 1.2-3l6-6c.8-.8 1.9-1.2
      3-1.2s2.2.4 3 1.2l13 13 13-13c.8-.8 1.9-1.2 3-1.2s2.2.4 3 1.2l6 6c.8.8
      1.2 1.9 1.2 3s-.4 2.2-1.2 3l-13 13 13 13c.8.8 1.2 1.9 1.2 3s-.4 2.2-1.2 3z"/>
    </svg>
  HTML

  FOUND_ICON = <<-HTML.freeze
    <svg width="55" height="55" class="cf-icon-found"
    xmlns="http://www.w3.org/2000/svg" viewBox="0 0 60 50">
      <title>found</title>
      <path d="M57 13.3L29.9 41.7 24.8 47c-.7.7-1.6 1.1-2.5 1.1-.9 0-1.9-.4-2.5-1.1l-5.1-5.3L1
       27.5c-.7-.7-1-1.7-1-2.7s.4-2 1-2.7l5.1-5.3c.7-.7 1.6-1.1 2.5-1.1.9 0 1.9.4 2.5 1.1l11
       11.6L46.8 2.7c.7-.7 1.6-1.1 2.5-1.1.9 0 1.9.4 2.5 1.1L57 8c.7.7 1 1.7 1 2.7 0 1-.4 1.9-1
       2.6z"/>
    </svg>
  HTML

  APPEAL_ICON = <<-HTML.freeze
    <svg width="16" height="16" class="cf-icon-appeal-id"
    xmlns="http://www.w3.org/2000/svg" viewBox="0 0 21 21">
    <title>appeal</title>
    <path d="M13.346 2.578h-2.664v-1.29C10.682.585 10.08 0 9.35 0H6.66c-.728 0-1.33.584-1.33
    1.29v1.288H2.663v2.577h10.682V2.578zm-4.02 0H6.66v-1.29h2.665v1.29zm6.685
    3.89V3.234a.665.665 0 0
    0-.678-.656H14v1.29h.68v2.576H6.66v9.046H1.333V3.867h.68v-1.29H.678a.665.665 0 0
    0-.68.657v12.913c0 .365.302.656.68.656h6.006v3.867h9.35l3.996-3.867V6.468h-4.02zm0
    12.378v-2.043h2.112l-2.11 2.043zm2.665-3.356H14.68v3.867H7.992v-11.6h10.682v7.733z"
    fill="#5B616B" fill-rule="evenodd"/></svg>
  HTML

  CLOSE_ICON = <<-HTML.freeze
    <svg style="pointer-events:none;" width="55" height="55" class="cf-icon-close"
    xmlns="http://www.w3.org/2000/svg" viewBox="0 0 55 55">
    <title>close</title>
    <path d="M52.6 46.9l-6 6c-.8.8-1.9 1.2-3 1.2s-2.2-.4-3-1.2l-13-13-13 13c-.8.8-1.9 1.2-3
    1.2s-2.2-.4-3-1.2l-6-6c-.8-.8-1.2-1.9-1.2-3s.4-2.2 1.2-3l13-13-13-13c-.8-.8-1.2-1.9-1.2-3s.4-2.2
    1.2-3l6-6c.8-.8 1.9-1.2 3-1.2s2.2.4 3 1.2l13 13 13-13c.8-.8 1.9-1.2 3-1.2s2.2.4 3 1.2l6 6c.8.8
    1.2 1.9 1.2 3s-.4 2.2-1.2 3l-13 13 13 13c.8.8 1.2 1.9 1.2 3s-.4 2.2-1.2 3z"/>
    </svg>
  HTML

  LOADING_ICON = <<-HTML.freeze
    <svg id="SVG-Circus-a3588196-df64-0703-ef88-f8c73c9558db"
      width="30"
      height="30"
      version="1.1" xmlns="http://www.w3.org/2000/svg"
      xmlns:xlink="http://www.w3.org/1999/xlink"
      viewBox="0 0 500 500"
      preserveAspectRatio="xMidYMid meet">

      <path
        opacity="1"
        fill="#d6d7d9"
        fill-opacity="1"
        d = "M250.9,469.4c-13.9,0-25.8-8.1-30.9-21l-29.9-75.3c-2.3-5.8-7.9-9.6-14.2-9.6c-0.8,0-1.6,0.1-2.4,0.2
        l-77,12.4c-1.8,0.3-3.7,0.4-5.5,0.4c-12.7,0-24.1-7.2-29.8-18.9c-5.6-11.6-4.1-25,3.9-35.1l50.2-63.4c4.5-5.7,4.4-13.5-0.1-19.1
        l-49.3-60.5c-8.2-10.1-9.8-23.6-4.3-35.3c5.6-11.8,17-19.1,29.9-19.1c1.7,0,3.4,0.1,5.1,0.4l80,11.7c0.7,0.1,1.5,0.2,2.2,0.2
        c6.3,0,12-4,14.2-9.8l27.8-72.9c5-13,17.2-21.5,31.1-21.5c13.9,0,25.8,8.1,30.9,21l29.8,75.2c2.3,5.8,7.9,9.6,14.2,9.6
        c0.8,0,1.6-0.1,2.4-0.2l77.1-12.4c1.8-0.3,3.7-0.4,5.5-0.4c12.7,0,24.1,7.2,29.8,18.9c5.6,11.6,4.1,25-3.9,35.1l-50.2,63.5
        c-4.5,5.7-4.4,13.5,0.1,19.1L437,323c8.2,10.1,9.8,23.6,4.3,35.3c-5.6,11.8-17,19.1-29.9,19.1c0,0,0,0,0,0c-1.7,0-3.4-0.1-5.1-0.4
        l-80.1-11.8c-0.7-0.1-1.5-0.2-2.2-0.2c-6.3,0-12,4-14.2,9.8l-27.8,73C277.1,460.9,264.8,469.4,250.9,469.4z M175.9,345.4
        c13.7,0,25.9,8.2,30.9,21l29.9,75.3c2.4,6,7.7,9.6,14.2,9.6c5.1,0,11.5-2.6,14.3-9.8l27.8-73c4.9-12.8,17.4-21.5,31.1-21.5
        c1.6,0,3.2,0.1,4.8,0.4l80.1,11.8c0.8,0.1,1.6,0.2,2.4,0.2h0c6.9,0,11.6-4.5,13.6-8.8c2.6-5.4,1.8-11.4-2-16.1l-49.3-60.5
        c-9.9-12.2-10.1-29.3-0.3-41.7l50.2-63.5c5.4-6.8,3-13.5,1.8-16c-2-4.2-6.7-8.7-13.5-8.7c-0.9,0-1.8,0.1-2.7,0.2l-77.1,12.4
        c-1.8,0.3-3.5,0.4-5.3,0.4c-13.7,0-25.9-8.2-30.9-21L266,60.9c-2.4-6-7.7-9.6-14.2-9.6c-5.1,0-11.5,2.6-14.3,9.8L209.8,134
        c-4.9,12.8-17.4,21.5-31.1,21.5c-1.6,0-3.2-0.1-4.8-0.4l-80-11.7c-0.8-0.1-1.6-0.2-2.4-0.2c-6.9,0-11.6,4.5-13.6,8.8
        c-2.6,5.4-1.8,11.4,2,16.1l49.3,60.5c9.9,12.2,10.1,29.3,0.3,41.7l-50.2,63.4c-5.4,6.8-3,13.5-1.8,16c2,4.2,6.7,8.7,13.5,8.7
        c0.9,0,1.8-0.1,2.7-0.2l77-12.4C172.3,345.5,174.1,345.4,175.9,345.4z">

        <animateTransform
                attributeType="xml"
                attributeName="transform"
                type="rotate"
                from="0 250 250"
                to="-360 250 250"
                dur="2s"
                repeatCount="indefinite"
            />
      </path>

      <path
        opacity="1"
        fill="#459FD7"
        fill-opacity="1"
        d = "M250.9,469.4c-13.9,0-25.8-8.1-30.9-21l-29.9-75.3c-2.3-5.8-7.9-9.6-14.2-9.6c-0.8,0-1.6,0.1-2.4,0.2
        l-77,12.4c-1.8,0.3-3.7,0.4-5.5,0.4c-12.7,0-24.1-7.2-29.8-18.9c-5.6-11.6-4.1-25,3.9-35.1l50.2-63.4c4.5-5.7,4.4-13.5-0.1-19.1
        l-49.3-60.5c-8.2-10.1-9.8-23.6-4.3-35.3c5.6-11.8,17-19.1,29.9-19.1c1.7,0,3.4,0.1,5.1,0.4l80,11.7c0.7,0.1,1.5,0.2,2.2,0.2
        c6.3,0,12-4,14.2-9.8l27.8-72.9c5-13,17.2-21.5,31.1-21.5c13.9,0,25.8,8.1,30.9,21l29.8,75.2c2.3,5.8,7.9,9.6,14.2,9.6
        c0.8,0,1.6-0.1,2.4-0.2l77.1-12.4c1.8-0.3,3.7-0.4,5.5-0.4c12.7,0,24.1,7.2,29.8,18.9c5.6,11.6,4.1,25-3.9,35.1l-50.2,63.5
        c-4.5,5.7-4.4,13.5,0.1,19.1L437,323c8.2,10.1,9.8,23.6,4.3,35.3c-5.6,11.8-17,19.1-29.9,19.1c0,0,0,0,0,0c-1.7,0-3.4-0.1-5.1-0.4
        l-80.1-11.8c-0.7-0.1-1.5-0.2-2.2-0.2c-6.3,0-12,4-14.2,9.8l-27.8,73C277.1,460.9,264.8,469.4,250.9,469.4z M175.9,345.4
        c13.7,0,25.9,8.2,30.9,21l29.9,75.3c2.4,6,7.7,9.6,14.2,9.6c5.1,0,11.5-2.6,14.3-9.8l27.8-73c4.9-12.8,17.4-21.5,31.1-21.5
        c1.6,0,3.2,0.1,4.8,0.4l80.1,11.8c0.8,0.1,1.6,0.2,2.4,0.2h0c6.9,0,11.6-4.5,13.6-8.8c2.6-5.4,1.8-11.4-2-16.1l-49.3-60.5
        c-9.9-12.2-10.1-29.3-0.3-41.7l50.2-63.5c5.4-6.8,3-13.5,1.8-16c-2-4.2-6.7-8.7-13.5-8.7c-0.9,0-1.8,0.1-2.7,0.2l-77.1,12.4
        c-1.8,0.3-3.5,0.4-5.3,0.4c-13.7,0-25.9-8.2-30.9-21L266,60.9c-2.4-6-7.7-9.6-14.2-9.6c-5.1,0-11.5,2.6-14.3,9.8L209.8,134
        c-4.9,12.8-17.4,21.5-31.1,21.5c-1.6,0-3.2-0.1-4.8-0.4l-80-11.7c-0.8-0.1-1.6-0.2-2.4-0.2c-6.9,0-11.6,4.5-13.6,8.8
        c-2.6,5.4-1.8,11.4,2,16.1l49.3,60.5c9.9,12.2,10.1,29.3,0.3,41.7l-50.2,63.4c-5.4,6.8-3,13.5-1.8,16c2,4.2,6.7,8.7,13.5,8.7
        c0.9,0,1.8-0.1,2.7-0.2l77-12.4C172.3,345.5,174.1,345.4,175.9,345.4z"
        transform="translate(250 250)">

        <animateTransform
                attributeType="xml"
                attributeName="transform"
                type="rotate"
                from="0 250 250"
                to="360 250 250"
                dur="2s"
                repeatCount="indefinite"
            />
      </path>
    </svg>
  HTML

  WINDOWS_LOGO_OLD_ICON = <<-HTML.freeze
    <svg version="1.1" class="cf-icon-win95" width="12.4" height="9.2" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px"
         viewBox="0 0 12.4 9.2" style="enable-background:new 0 0 12.4 9.2;" xml:space="preserve">
      <g>
        <path d="M0.9,1v0.3L0.5,1.5V1.1L0.9,1z M0.9,4.3v0.3L0.5,4.8V4.5L0.9,4.3z M0.9,7.7v0.4L0.5,8.2V7.9L0.9,7.7z M0.9,2.1v0.3L0.6,2.5
          V2.2L0.9,2.1z M0.9,3.2v0.3L0.6,3.7V3.4L0.9,3.2z M0.9,5.5v0.3L0.6,5.9V5.6L0.9,5.5z M0.9,6.6v0.3L0.6,7.1V6.8L0.9,6.6z M2,1.2v0.4
          L1.4,1.8V1.4L2,1.2z M2,4.6V5L1.4,5.2V4.8L2,4.6z M2,8v0.4L1.4,8.6V8.2L2,8z M1.9,2.3v0.4L1.5,2.9V2.5L1.9,2.3z M1.9,3.5v0.4L1.5,4
          V3.6L1.9,3.5z M1.9,5.7v0.4L1.5,6.3V5.9L1.9,5.7z M1.9,6.9v0.4L1.5,7.4V7L1.9,6.9z M3,1.4v0.5L2.3,2.2V1.7L3,1.4z M3,4.8v0.5
          L2.3,5.6V5.1L3,4.8z M3,8.2v0.5L2.3,8.9V8.4L3,8.2z M3,2.6V3L2.4,3.2V2.8L3,2.6z M3,3.7v0.4L2.4,4.4V4L3,3.7z M3,6v0.4L2.4,6.6V6.2
          L3,6z M3,7.1v0.4L2.4,7.7V7.3L3,7.1z M4.1,1.4V2L3.2,2.4V1.7L4.1,1.4z M4.1,4.8v0.6L3.2,5.8V5.1L4.1,4.8z M4.1,8.1v0.6L3.2,9.1V8.5
          L4.1,8.1z M4.1,2.6v0.6L3.3,3.4V2.9L4.1,2.6z M4.1,3.7v0.6L3.3,4.6V4L4.1,3.7z M4.1,6v0.6L3.3,6.8V6.2L4.1,6z M4.1,7v0.6L3.3,7.9
          V7.3L4.1,7z M5.3,1.3v0.8l-1,0.4V1.7L5.3,1.3z M5.3,4.7v0.8l-1,0.4V5.1L5.3,4.7z M5.3,8v0.8l-1,0.4V8.4L5.3,8z M5.2,2.5v0.7
          L4.4,3.5V2.9L5.2,2.5z M5.2,3.6v0.7L4.4,4.6V3.9L5.2,3.6z M5.2,5.9v0.7L4.4,6.9V6.2L5.2,5.9z M5.2,7v0.7L4.4,8V7.3L5.2,7z M6.4,0.9
          V2l-1,0.4V1.4C5.8,1.2,6.1,1,6.4,0.9z M6.4,2.1v1l-1,0.4v-1L6.4,2.1z M6.4,3.2v1l-1,0.4v-1L6.4,3.2z M6.4,4.3v1l-1,0.4v-1L6.4,4.3z
           M6.4,5.4v1l-1,0.4v-1L6.4,5.4z M6.4,6.6v1L5.4,8V7L6.4,6.6z M6.4,7.7v1.1C6,8.9,5.7,9,5.4,9.2V8.1L6.4,7.7z M11.8,0.9v7.9
          c-0.7-0.4-1.5-0.7-2.5-0.7c-0.8,0-1.8,0.2-2.8,0.5V7.6c0.5-0.2,1.1-0.4,1.8-0.5V4.6C7.8,4.6,7.2,4.8,6.6,5.1V4.4
          C7.1,4.1,7.7,4,8.3,3.9V1.4C7.8,1.5,7.2,1.7,6.6,1.9V0.8c0.9-0.4,1.8-0.6,2.7-0.6C10.2,0.2,11,0.5,11.8,0.9z M10.8,1.6
          c-0.4-0.2-0.9-0.3-1.5-0.3c-0.1,0-0.1,0-0.2,0v2.5l0.2,0c0.5,0,1,0.1,1.5,0.2V1.6z M10.8,4.8c-0.5-0.2-1-0.3-1.5-0.3
          c-0.1,0-0.1,0-0.2,0v2.6h0.2c0.6,0,1.1,0.1,1.5,0.2V4.8z M11.5,9.1V9h-0.1v0h0.2v0h-0.1L11.5,9.1L11.5,9.1z M11.6,9.1V8.9h0
          l0.1,0.2l0.1-0.2h0v0.2h0V9l-0.1,0.2h0L11.6,9L11.6,9.1L11.6,9.1z"/>
      </g>
    </svg>
  HTML

  WINDOWS_LOGO_ICON = <<-HTML.freeze
    <svg version="1.1" width="11.9" height="11.7" class="cf-icon-win8" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px"
       viewBox="0 0 11.9 11.7" style="enable-background:new 0 0 11.9 11.7;" xml:space="preserve"><title>Windows 8 or higher icon</title>
    <g>
      <path d="M4.9,5.6H0.4V1.8l4.6-0.6V5.6z M4.9,10.5L0.4,9.9V6.2h4.6V10.5z M11.5,5.6H5.4V1.1l6.1-0.8V5.6z M11.5,11.4l-6.1-0.8V6.2
        h6.1V11.4z"/>
    </g>
    </svg>
  HTML

  def svg_icon(name)
    {
      missing: MISSING_ICON,
      found: FOUND_ICON,
      appeal: APPEAL_ICON,
      close: CLOSE_ICON,
      loading: LOADING_ICON,
      windows_logo_old: WINDOWS_LOGO_OLD_ICON,
      windows_logo: WINDOWS_LOGO_ICON
    }[name].html_safe
  end

  def loading_indicator
    content_tag :div, class: "cf-loading-indicator cf-push-right" do
      "Loading #{svg_icon(:loading)}".html_safe
    end
  end
end
