import React, { Component } from "react";
import { Button} from "react-bootstrap";
import styles from "../App.css";

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
        <Button>Go back home</Button>
      </div>

    );
  }
}