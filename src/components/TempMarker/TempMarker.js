import React from "react";
import withStyles from "isomorphic-style-loader/withStyles";
import s from "./TempMarker.scss";

const TempMarker = () => (
  <div className={s.tempMarker}>
    <svg viewBox="-2 -2 19 19" width="19" height="19">
      <circle
        className={s.tempMarkerCircle}
        strokeWidth="2"
        stroke="#000"
        fill="transparent"
        strokeDasharray="2.95, 2.95"
        r="7.5"
        cx="7.5"
        cy="7.5"
      />
    </svg>
  </div>
);

export default withStyles(s)(TempMarker);
