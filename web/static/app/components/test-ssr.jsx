import React from "react";
import MuiThemeProvider from "material-ui/styles/MuiThemeProvider";
import SelectField from 'material-ui/SelectField';
import MenuItem from 'material-ui/MenuItem';



export default (props) => (
  <MuiThemeProvider>
    <SelectField floatingLabelText="Select cluster">
      {props.clusters.map(cluster => (
        <MenuItem value={cluster.id} primaryText={cluster.label} />
      ))}
    </SelectField>
  </MuiThemeProvider>
);
