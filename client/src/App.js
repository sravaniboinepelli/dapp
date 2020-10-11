import './App.css';
import { BrowserRouter as Router, Route, Switch } from "react-router-dom";
import "bootstrap/dist/css/bootstrap.min.css";
import Landing from "./components/Landing";
import React, { Component } from "react";
import { Button, DropdownButton, Dropdown, ButtonGroup, Form } from "react-bootstrap";
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import { faSquare, faDiceOne, faDiceThree, faDiceTwo, faDiceFour, faDiceFive, faDiceSix } from '@fortawesome/free-solid-svg-icons'
import SetString from './components/SetString'
import Game from './Game'

class App extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      loading: true,
      drizzleState: null,
    };

    // for (var i = 0; i < this.state.no_players; i++)
    //   no_dice.push(this.state.og_dice);
    // this.state.no_dice = no_dice;

    // var no_players = this.state.no_players;
    // var config = []
    // for (var i = 0; i < no_players; i++) {
    //   var player_config = [];
    //   for (var j = 0; j < this.state.no_dice[i]; j++)
    //     player_config.push(1 + Math.floor(Math.random() * 6));
    //   config.push(player_config);
    // }

    // this.state.config = config;
  }

componentDidMount() {

    const { drizzle } = this.props;
    this.unsubscribe = drizzle.store.subscribe(() => {
      const drizzleState = drizzle.store.getState();
      if (drizzleState.drizzleStatus.initialized) {
        this.setState({ loading: false, drizzleState });
      }
    });
  }
  componentWillUnmount() {
    this.unsubscribe();
  }

  render() {
    if (this.state.loading) return "Loading Drizzle...";
    //console.log(this.state)
    return (
      
      <div className="App">
        <Game
          drizzle={this.props.drizzle}
          drizzleState={this.state.drizzleState}
        />
      </div>

    );
  }
}

export default App;

