import React, { Component } from "react";
import { Button} from "react-bootstrap";
import styles from "../App.css";
import { Link } from "react-router-dom";

export default class Error extends Component {
  constructor(props) {
    super(props);
    this.state = {
    };
  }

  render() {
    return (
        <div class="page">
        <h1>Are you lost at sea?</h1>
        <img class="error" src={require('../assets/404-lost-at-sea.gif')} />
        <br/>
        <Link to="/">
        <Button>Go back home</Button>
        </Link>
      </div>

    );
  }
}
