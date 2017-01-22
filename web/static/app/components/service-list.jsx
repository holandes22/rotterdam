import React from "react";


export default class ServiceList extends React.Component {

  render() {
    return (
      <div>
      <div className="row">
        <div className="col-xs"><div className="box">Name</div></div>
        <div className="col-xs"><div className="box">Replicas</div></div>
        <div className="col-xs"><div className="box">Image</div></div>
        <div className="col-xs"><div className="box">ID</div></div>
      </div>
      {this.getServices().map(service => (
        <div className="row" key={service.id}>
          <div className="col-xs"><div className="box">{service.name}</div></div>
          <div className="col-xs"><div className="box">{service.replicas}</div></div>
          <div className="col-xs"><div className="box">{service.image}</div></div>
          <div className="col-xs"><div className="box">{service.id.slice(12)}</div></div>
        </div>
      ))}
    </div>
    );
  }

  getServices() {
    let services = [];

    this.props.services.map(service => {
      let spec = service.Spec;
      let id = service.ID
      let name = spec.Name;
      let replicas = (spec.Mode.Replicated) ? spec.Mode.Replicated.Replicas : "N/A";
      let image = spec.TaskTemplate.ContainerSpec.Image;
      services.push({id, name, replicas, image})
    })
    return services;
  }
}
