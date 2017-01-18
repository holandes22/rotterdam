import React from "react";


export default class ServiceList extends React.Component {

  render() {
    return (
      <ul>
        {this.props.services.map(service => (
          <li key={service.ID}>{service.CreatedAt}</li>
        ))}
      </ul>
    );
  }
}
