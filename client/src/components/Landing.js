import React, { Component } from "react";
import { Button} from "react-bootstrap";
import styles from "../App.css";
import { Link } from "react-router-dom";

export default class Landing extends Component {
  constructor(props) {
    super(props);
    this.state = {
    };
  }

  render() {
    return (
        <div className="landingBody">

        <div className="content">
          <h1 className="heading">Queen Anne's Revenge</h1>
          <h4 className="subheading">
          Find out who is bluffing and claim the prize!          
          </h4>
          <Link to="/play">
            <Button variant="danger" size="lg">
              Play Now
            </Button>
            </Link>
        </div>
      </div>

    );
  }
}