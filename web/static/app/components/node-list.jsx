import React from "react";
import MuiThemeProvider from "material-ui/styles/MuiThemeProvider";
import {Table, TableBody, TableHeader, TableHeaderColumn, TableRow, TableRowColumn} from 'material-ui/Table';
import getMuiTheme from "material-ui/styles/getMuiTheme";
import colors from "modules/_colors.scss";
import {textColor} from "modules/_colors.scss";


const muiTheme = getMuiTheme({
  palette: {
    textColor,
    canvasColor: colors["background-color"]
  }
});


const NodeList = (props) => (
  <MuiThemeProvider muiTheme={muiTheme}>
    <Table >
      <TableHeader>
        <TableRow>
          <TableHeaderColumn>Hostname</TableHeaderColumn>
          <TableHeaderColumn>Status</TableHeaderColumn>
          <TableHeaderColumn>Availability</TableHeaderColumn>
          <TableHeaderColumn>Manager Status</TableHeaderColumn>
          <TableHeaderColumn>ID</TableHeaderColumn>
        </TableRow>
      </TableHeader>
      <TableBody>
        {props.nodes.map(node => (
        <TableRow key={node.id}>
          <TableRowColumn>{node.hostname}</TableRowColumn>
          <TableRowColumn>{node.state}</TableRowColumn>
          <TableRowColumn>{node.availability}</TableRowColumn>
          <TableRowColumn>{node.leader ? "Leader" : ""}</TableRowColumn>
          <TableRowColumn>{node.id.slice(12)}</TableRowColumn>
        </TableRow>
        ))}
      </TableBody>
    </Table>
  </MuiThemeProvider>
);

export default NodeList;
