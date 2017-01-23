import React from "react";
import MuiThemeProvider from 'material-ui/styles/MuiThemeProvider';
import {Table, TableBody, TableHeader, TableHeaderColumn, TableRow, TableRowColumn} from 'material-ui/Table';
import getMuiTheme from 'material-ui/styles/getMuiTheme';
import colors from 'modules/_colors.scss';
import {textColor} from 'modules/_colors.scss';


const muiTheme = getMuiTheme({
  palette: {
    textColor,
    canvasColor: colors["background-color"]
  }
});

const getServices = (services) => {
  let retval = [];

  services.map(service => {
    let spec = service.Spec;
    let id = service.ID
    let name = spec.Name;
    let replicas = (spec.Mode.Replicated) ? spec.Mode.Replicated.Replicas : "N/A";
    let image = spec.TaskTemplate.ContainerSpec.Image;
    retval.push({id, name, replicas, image})
  })
  return retval;
}

const ServiceList = (props) => (
  <MuiThemeProvider muiTheme={muiTheme}>
    <Table >
      <TableHeader>
        <TableRow>
          <TableHeaderColumn>Name</TableHeaderColumn>
          <TableHeaderColumn>Replicas</TableHeaderColumn>
          <TableHeaderColumn>Image</TableHeaderColumn>
          <TableHeaderColumn>ID</TableHeaderColumn>
        </TableRow>
      </TableHeader>
      <TableBody>
        {getServices(props.services).map(service => (
        <TableRow key={service.id}>
          <TableRowColumn>{service.name}</TableRowColumn>
          <TableRowColumn>{service.replicas}</TableRowColumn>
          <TableRowColumn>{service.image}</TableRowColumn>
          <TableRowColumn>{service.id.slice(12)}</TableRowColumn>
        </TableRow>
        ))}
      </TableBody>
    </Table>
  </MuiThemeProvider>
);

export default ServiceList;
